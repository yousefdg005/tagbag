const { neon } = require('@neondatabase/serverless');
const sql = neon('postgresql://neondb_owner:npg_frNAe0Tb8wEs@ep-dark-wave-bdz7xhnb-pooler.c-8.us-east-2.aws.neon.tech/neondb?sslmode=require');

async function main() {
  const users = await sql('SELECT full_name, role, phone FROM users WHERE role = $1', ['therapist']);
  console.log('✅ Found Therapists directly in Neon:');
  console.log(users);
}

main().catch(console.error);
