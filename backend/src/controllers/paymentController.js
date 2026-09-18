import Stripe from "stripe";
import axios from "axios";
import { env } from "../config/env.js";
import { pool, query } from "../db.js";

const prices = {
  monthly: {
    amount: 499,
    currency: "KES",
    days: 31,
  },
  annual: {
    amount: 4999,
    currency: "KES",
    days: 365,
  },
};

function addDays(date, days) {
  const result = new Date(date);
  result.setDate(result.getDate() + days);
  return result;
}

async function activate(userId, plan, method, providerRef) {
  const price = prices[plan];

  if (!price) {
    throw new Error("Invalid subscription plan");
  }

  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    // Expire any previous active subscription
    await client.query(
      `
      UPDATE subscriptions
      SET status = 'expired',
          updated_at = NOW()
      WHERE user_id = $1
        AND status = 'active'
      `,
      [userId]
    );

    // Record payment
    await client.query(
      `
      INSERT INTO payments (
        user_id,
        amount,
        currency,
        provider,
        provider_reference,
        status,
        paid_at
      )
      VALUES ($1, $2, $3, $4, $5, 'successful', NOW())
      ON CONFLICT DO NOTHING
      `,
      [
        userId,
        price.amount,
        price.currency,
        method,
        providerRef,
      ]
    );

    const startDate = new Date();
    const endDate = addDays(startDate, price.days);

    // Create active subscription
    await client.query(
      `
      INSERT INTO subscriptions (
  user_id,
  plan,
  status,
  amount,
  start_date,
  end_date,
  provider
)
VALUES ($1, $2, 'active', $3, $4, $5, $6)
      `,
      [
  userId,
  plan,
  price.amount,
  startDate,
  endDate,
  method,
]
    );

    await client.query("COMMIT");
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
}

async function mpesaToken() {
  const host =
    env.mpesaEnv === "production"
      ? "https://api.safaricom.co.ke"
      : "https://sandbox.safaricom.co.ke";

  const auth = Buffer.from(
    `${env.mpesaConsumerKey}:${env.mpesaConsumerSecret}`
  ).toString("base64");

  const { data } = await axios.get(
    `${host}/oauth/v1/generate?grant_type=client_credentials`,
    {
      headers: {
        Authorization: `Basic ${auth}`,
      },
    }
  );

  return {
    host,
    token: data.access_token,
  };
}

async function mpesaStk({ phone, plan, userId }) {
  if (!/^2547\d{8}$/.test(phone)) {
    throw new Error(
      "Use a Kenyan M-Pesa number such as 2547XXXXXXXX"
    );
  }

  const { host, token } = await mpesaToken();
  const timestamp = new Date()
    .toISOString()
    .replace(/\D/g, "")
    .slice(0, 14);

  const password = Buffer.from(
    `${env.mpesaShortcode}${env.mpesaPasskey}${timestamp}`
  ).toString("base64");

  const price = prices[plan];

  const response = await axios.post(
    `${host}/mpesa/stkpush/v1/processrequest`,
    {
      BusinessShortCode: env.mpesaShortcode,
      Password: password,
      Timestamp: timestamp,
      TransactionType: "CustomerPayBillOnline",
      Amount: price.amount,
      PartyA: phone,
      PartyB: env.mpesaShortcode,
      PhoneNumber: phone,
      CallBackURL: env.mpesaCallbackUrl,
      AccountReference: `LEARNSCI-${userId}`,
      TransactionDesc: `LearnSci ${plan} subscription`,
    },
    {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    }
  );

  return response.data;
}

export async function checkout(req, res) {
  try {
    const { plan, method, phone } = req.body;

    if (
      !prices[plan] ||
      !["mpesa", "stripe"].includes(method)
    ) {
      return res.status(400).json({
        message: "Invalid checkout selection",
      });
    }

    // Stripe checkout
    if (method === "stripe") {
      if (!env.stripeSecret) {
        return res.status(503).json({
          message:
            "Stripe is not configured. Use M-Pesa or the development simulation.",
        });
      }

      const stripe = new Stripe(env.stripeSecret);

      const session =
        await stripe.checkout.sessions.create({
          mode: "payment",

          line_items: [
            {
              price_data: {
                currency: "kes",
                product_data: {
                  name: `LearnSci ${plan} subscription`,
                },
                unit_amount:
                  prices[plan].amount * 100,
              },
              quantity: 1,
            },
          ],

          metadata: {
            userId: String(req.user.id),
            plan,
          },

          success_url: env.stripeSuccessUrl,
          cancel_url: env.stripeCancelUrl,
        });

      return res.json({
        redirectUrl: session.url,
      });
    }

    // M-Pesa checkout
    if (!env.mpesaConsumerKey) {
      return res.status(503).json({
        message:
          "M-Pesa is not configured. Use the development simulation.",
      });
    }

    const result = await mpesaStk({
      phone,
      plan,
      userId: req.user.id,
    });

    return res.json({
      message:
        result.CustomerMessage ||
        "Check your phone and enter your M-Pesa PIN.",
      checkoutRequestId:
        result.CheckoutRequestID,
      merchantRequestId:
        result.MerchantRequestID,
    });
  } catch (error) {
    console.error("Checkout error:", error);

    return res.status(400).json({
      message:
        error.response?.data?.errorMessage ||
        error.message ||
        "Checkout failed",
    });
  }
}

export async function simulateSuccess(req, res) {
  try {
    if (env.nodeEnv === "production") {
      return res.status(403).json({
        message: "Simulation disabled in production",
      });
    }

    const { plan, method } = req.body;

    if (!prices[plan]) {
      return res.status(400).json({
        message: "Invalid plan",
      });
    }

    await activate(
      req.user.id,
      plan,
      method || "simulation",
      `SIM-${Date.now()}`
    );

    return res.json({
      ok: true,
    });
  } catch (error) {
    console.error("Simulation error:", error);

    return res.status(500).json({
      message: error.message || "Simulation failed",
    });
  }
}

export async function history(req, res) {
  try {
    const { rows } = await query(
      `
      SELECT
        id,
        amount,
        currency,
        provider,
        status,
        provider_reference,
        paid_at
      FROM payments
      WHERE user_id = $1
      ORDER BY created_at DESC
      `,
      [req.user.id]
    );

    return res.json({
      payments: rows,
    });
  } catch (error) {
    console.error("Payment history error:", error);

    return res.status(500).json({
      message: "Could not retrieve payment history",
    });
  }
}

export async function subscription(req, res) {
  try {
    const { rows } = await query(
      `
      SELECT *
      FROM subscriptions
      WHERE user_id = $1
      ORDER BY created_at DESC
      LIMIT 1
      `,
      [req.user.id]
    );

    return res.json({
      subscription: rows[0] || null,
    });
  } catch (error) {
    console.error("Subscription error:", error);

    return res.status(500).json({
      message: "Could not retrieve subscription",
    });
  }
}

export async function mpesaCallback(req, res) {
  try {
    const callback = req.body?.Body?.stkCallback;

    if (!callback) {
      return res.json({
        ResultCode: 0,
        ResultDesc: "Accepted",
      });
    }

    if (Number(callback.ResultCode) !== 0) {
      return res.json({
        ResultCode: 0,
        ResultDesc: "Received failed payment",
      });
    }

    const metadata = Object.fromEntries(
      (callback.CallbackMetadata?.Item || []).map(
        (item) => [item.Name, item.Value]
      )
    );

    const account = String(
      metadata.AccountReference || ""
    );

    const userId = account.replace(
      "LEARNSCI-",
      ""
    );

    if (!/^\d+$/.test(userId)) {
      return res.json({
        ResultCode: 0,
        ResultDesc: "Received",
      });
    }

    const { rows } = await query(
      "SELECT id FROM users WHERE id = $1",
      [userId]
    );

    if (!rows[0]) {
      return res.json({
        ResultCode: 0,
        ResultDesc: "Received",
      });
    }

    const amount = Number(
      metadata.Amount || 0
    );

    let plan;

    if (amount === prices.annual.amount) {
      plan = "annual";
    } else if (amount === prices.monthly.amount) {
      plan = "monthly";
    } else {
      return res.json({
        ResultCode: 0,
        ResultDesc: "Invalid subscription amount",
      });
    }

    await activate(
      userId,
      plan,
      "mpesa",
      String(
        metadata.MpesaReceiptNumber ||
          callback.CheckoutRequestID
      )
    );

    return res.json({
      ResultCode: 0,
      ResultDesc: "Accepted",
    });
  } catch (error) {
    console.error("M-Pesa callback error:", error);

    return res.json({
      ResultCode: 0,
      ResultDesc: "Received",
    });
  }
}

export async function stripeWebhook(req, res) {
  if (
    !env.stripeSecret ||
    !env.stripeWebhookSecret
  ) {
    return res.status(503).send(
      "Stripe not configured"
    );
  }

  const stripe = new Stripe(env.stripeSecret);

  let event;

  try {
    event =
      stripe.webhooks.constructEvent(
        req.body,
        req.headers["stripe-signature"],
        env.stripeWebhookSecret
      );
  } catch (error) {
    return res.status(400).send(
      `Webhook Error: ${error.message}`
    );
  }

  if (
    event.type ===
    "checkout.session.completed"
  ) {
    const session = event.data.object;

    if (
      session.payment_status === "paid" &&
      session.metadata?.userId &&
      session.metadata?.plan
    ) {
      await activate(
        session.metadata.userId,
        session.metadata.plan,
        "stripe",
        session.payment_intent ||
          session.id
      );
    }
  }

  return res.json({
    received: true,
  });
}