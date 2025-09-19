// worker.js
export async function onRequestPost(context) {
  try {
    const data = await context.request.json();

    const stmt = context.env.DB.prepare(`
      INSERT INTO waitlist (
        user_name, first_name, surname, email, contact_number, user_type,
        country, location, skill_set, date_of_birth, gender, created_date
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);

    await stmt
      .bind(
        data.user_name,
        data.first_name,
        data.surname,
        data.email,
        data.contact_number,
        data.user_type,
        data.country || "South Africa",
        data.location,
        data.skill_set,
        data.date_of_birth,
        data.gender,
        data.created_date || new Date().toISOString()
      )
      .run();

    return new Response(JSON.stringify({ success: true }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (err) {
    console.error("Error inserting into waitlist:", err);
    return new Response(JSON.stringify({ error: "Failed to insert user" }), {
      headers: { "Content-Type": "application/json" },
      status: 500,
    });
  }
}