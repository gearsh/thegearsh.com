// worker.js
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    if (request.method === "POST" && url.pathname === "/api/waitlist") {
      try {
        const data = await request.json();

        const stmt = env.DB.prepare(`
          INSERT INTO waitlist (
            user_name, first_name, surname, email, contact_number, user_type,
            country, location, skill_set, date_of_birth, gender, created_date
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `);

        const result = await stmt.bind(
          data.user_name,
          data.first_name,
          data.surname,
          data.email,
          data.contact_number,
          data.user_type,
          data.country || 'South Africa',
          data.location,
          data.skill_set,
          data.date_of_birth,
          data.gender,
          data.created_date
        ).run();

        return new Response(JSON.stringify({ success: true }), {
          headers: { "Content-Type": "application/json" },
          status: 200
        });

      } catch (err) {
        console.error("Error inserting into waitlist:", err);
        return new Response(JSON.stringify({ error: "Failed to insert user" }), {
          headers: { "Content-Type": "application/json" },
          status: 500
        });
      }
    }

    return new Response("Not Found", { status: 404 });
  }
};
