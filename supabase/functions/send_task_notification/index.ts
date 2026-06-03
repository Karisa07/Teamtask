// Supabase Edge Functions runtime.
// Nota: TS local puede no entender imports `jsr:`; el deploy en Supabase sí.
// @ts-nocheck
import { withSupabase } from "jsr:@supabase/server@^1";


interface ReqPayload {
  user_id: string;
  board_id: string;
  task_id: string;
  title: string;
  body: string;
}

type EdgeReq = Request;
type EdgeCtx = { supabase: any };

export default {
  fetch: withSupabase({ auth: ["publishable", "secret"] }, async (req: EdgeReq, ctx: EdgeCtx) => {

    if (req.method !== "POST") {
      return new Response(JSON.stringify({ error: "Method not allowed" }), {
        status: 405,
        headers: { "Content-Type": "application/json" },
      });
    }

    const payload = (await req.json()) as ReqPayload;

    const { user_id, board_id, task_id, title, body: notificationBody } = payload;

    if (!user_id || !board_id || !task_id || !title || !notificationBody) {
      return new Response(JSON.stringify({ error: "Missing required fields" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Use the privileged client. The withSupabase wrapper gives access to the right client.
    const sb = ctx.supabase;

    // Check toggle
    const { data: profile, error: profileErr } = await sb
      .from("profiles")
      .select("notifications_enabled")
      .eq("id", user_id)
      .maybeSingle();

    if (profileErr) {
      return new Response(JSON.stringify({ error: profileErr.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (!profile || profile.notifications_enabled !== true) {
      return new Response(JSON.stringify({ ok: true, skipped: true }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Insert notification event for the client to convert into a local notification
    const { data, error } = await sb
      .from("notification_events")
      .insert({
        user_id,
        board_id,
        task_id,
        title,
        body: notificationBody,
      })
      .select()
      .single();

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    return new Response(
      JSON.stringify({ ok: true, notification_event_id: data.id }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" },
      }
    );
  }),
};

