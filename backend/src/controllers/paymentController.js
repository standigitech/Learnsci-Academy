import Stripe from "stripe";
import axios from "axios";
import crypto from "node:crypto";
import { env } from "../config/env.js";
import { pool, query } from "../db.js";

const prices = {
  monthly: { amount: 499, currency: "KES", days: 31 },
  annual: { amount: 4999, currency: "KES", days: 365 }
};
function addDays(d,n){const x=new Date(d);x.setDate(x.getDate()+n);return x;}

async function activate(userId,plan,method,providerRef){
  const p=prices[plan];
  const client=await pool.connect();
  try{
    await client.query("BEGIN");
    await client.query(`UPDATE subscriptions SET status='expired',updated_at=NOW() WHERE user_id=$1 AND status='active'`,[userId]);
    await client.query(`INSERT INTO payments(user_id,amount,currency,provider,provider_reference,status,paid_at) VALUES($1,$2,$3,$4,$5,'paid',NOW()) ON CONFLICT DO NOTHING`,[userId,p.amount,p.currency,method,providerRef]);
    await client.query(`INSERT INTO subscriptions(user_id,plan,status,current_period_start,current_period_end,provider) VALUES($1,$2,'active',NOW(),$3,$4)`,[userId,plan,addDays(new Date(),p.days),method]);
    await client.query("COMMIT");
  }catch(e){await client.query("ROLLBACK");throw e;}finally{client.release();}
}

async function mpesaToken(){
  const host=env.mpesaEnv==="production"?"https://api.safaricom.co.ke":"https://sandbox.safaricom.co.ke";
  const auth=Buffer.from(`${env.mpesaConsumerKey}:${env.mpesaConsumerSecret}`).toString("base64");
  const {data}=await axios.get(`${host}/oauth/v1/generate?grant_type=client_credentials`,{headers:{Authorization:`Basic ${auth}`}});
  return {host,token:data.access_token};
}

async function mpesaStk({phone,plan,userId}){
  if(!/^2547\d{8}$/.test(phone)) throw new Error("Use a Kenyan M-Pesa number such as 2547XXXXXXXX");
  const {host,token}=await mpesaToken();
  const timestamp=new Date().toISOString().replace(/\D/g,"").slice(0,14);
  const password=Buffer.from(`${env.mpesaShortcode}${env.mpesaPasskey}${timestamp}`).toString("base64");
  const p=prices[plan];
  const response=await axios.post(`${host}/mpesa/stkpush/v1/processrequest`,{
    BusinessShortCode:env.mpesaShortcode,Password:password,Timestamp:timestamp,TransactionType:"CustomerPayBillOnline",
    Amount:p.amount,PartyA:phone,PartyB:env.mpesaShortcode,PhoneNumber:phone,CallBackURL:env.mpesaCallbackUrl,
    AccountReference:`LEARNSCI-${userId}`,TransactionDesc:`LearnSci ${plan} subscription`
  },{headers:{Authorization:`Bearer ${token}`}});
  return response.data;
}

export async function checkout(req,res){
  try{
    const {plan,method,phone}=req.body;
    if(!prices[plan]||!["mpesa","stripe"].includes(method))return res.status(400).json({message:"Invalid checkout selection"});
    if(method==="stripe"){
      if(!env.stripeSecret)return res.status(503).json({message:"Stripe is not configured. Use M-Pesa or the development simulation."});
      const stripe=new Stripe(env.stripeSecret);
      const session=await stripe.checkout.sessions.create({mode:"payment",line_items:[{price_data:{currency:"kes",product_data:{name:`LearnSci ${plan} subscription`},unit_amount:prices[plan].amount*100},quantity:1}],metadata:{userId:String(req.user.id),plan},success_url:env.stripeSuccessUrl,cancel_url:env.stripeCancelUrl});
      return res.json({redirectUrl:session.url});
    }
    if(!env.mpesaConsumerKey)return res.status(503).json({message:"M-Pesa is not configured. Use the development simulation."});
    const result=await mpesaStk({phone,plan,userId:req.user.id});
    return res.json({message:result.CustomerMessage||"Check your phone and enter your M-Pesa PIN.",checkoutRequestId:result.CheckoutRequestID,merchantRequestId:result.MerchantRequestID});
  }catch(e){return res.status(400).json({message:e.response?.data?.errorMessage||e.message||"Checkout failed"});}
}

export async function simulateSuccess(req,res){
  if(env.nodeEnv==="production")return res.status(403).json({message:"Simulation disabled in production"});
  const {plan,method}=req.body;
  if(!prices[plan])return res.status(400).json({message:"Invalid plan"});
  await activate(req.user.id,plan,method||"simulation",`SIM-${Date.now()}`);
  res.json({ok:true});
}

export async function history(req,res){const {rows}=await query("SELECT id,amount,currency,provider,status,provider_reference,paid_at FROM payments WHERE user_id=$1 ORDER BY created_at DESC",[req.user.id]);res.json({payments:rows});}
export async function subscription(req,res){const {rows}=await query("SELECT * FROM subscriptions WHERE user_id=$1 ORDER BY created_at DESC LIMIT 1",[req.user.id]);res.json({subscription:rows[0]||null});}

export async function mpesaCallback(req,res){
  try{
    const callback=req.body?.Body?.stkCallback;
    if(!callback)return res.json({ResultCode:0,ResultDesc:"Accepted"});
    if(Number(callback.ResultCode)!==0)return res.json({ResultCode:0,ResultDesc:"Received failed payment"});
    const meta=Object.fromEntries((callback.CallbackMetadata?.Item||[]).map(x=>[x.Name,x.Value]));
    const account=String(meta.AccountReference||"");
    const userId=account.replace("LEARNSCI-","");
    if(!/^\d+$/.test(userId))return res.json({ResultCode:0,ResultDesc:"Received"});
    const {rows}=await query("SELECT id FROM users WHERE id=$1",[userId]);
    if(!rows[0])return res.json({ResultCode:0,ResultDesc:"Received"});
    const amount=Number(meta.Amount||0);
    const plan=amount===prices.annual.amount?"annual":"monthly";
    await activate(userId,plan,"mpesa",String(meta.MpesaReceiptNumber||callback.CheckoutRequestID));
    return res.json({ResultCode:0,ResultDesc:"Accepted"});
  }catch(e){console.error("M-Pesa callback",e);return res.json({ResultCode:0,ResultDesc:"Received"});}
}

export async function stripeWebhook(req,res){
  if(!env.stripeSecret||!env.stripeWebhookSecret)return res.status(503).send("Stripe not configured");
  const stripe=new Stripe(env.stripeSecret);
  let event;
  try{event=stripe.webhooks.constructEvent(req.body,req.headers["stripe-signature"],env.stripeWebhookSecret);}catch(e){return res.status(400).send(`Webhook Error: ${e.message}`);}
  if(event.type==="checkout.session.completed"){
    const session=event.data.object;
    if(session.payment_status==="paid")await activate(session.metadata.userId,session.metadata.plan,"stripe",session.payment_intent||session.id);
  }
  res.json({received:true});
}
