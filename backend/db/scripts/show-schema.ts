import fs from 'fs'
import path from 'path'

const schemaPath = path.resolve(process.cwd(), 'db/schema.sql')
const setupPath = path.resolve(process.cwd(), 'db/setup_supabase.sql')
const migrationsDir = path.resolve(process.cwd(), 'db/migrations')

console.log('====================================================')
console.log('GroupLock Database Architecture Summary')
console.log('====================================================')

const activeSchema = fs.existsSync(setupPath) ? setupPath : schemaPath
if (fs.existsSync(activeSchema)) {
  const content = fs.readFileSync(activeSchema, 'utf-8')
  const tableMatches = content.match(/create table if not exists public\.(\w+)/g) || []
  console.log(`\n📋 Database Tables (${tableMatches.length} total from ${path.basename(activeSchema)}):`)
  tableMatches.forEach(t => {
    const name = t.replace('create table if not exists public.', '')
    console.log(`   - public.${name}`)
  })
}

if (fs.existsSync(migrationsDir)) {
  const migrations = fs.readdirSync(migrationsDir)
  console.log(`\n📦 Migration Files (${migrations.length} total in db/migrations/):`)
  migrations.forEach(m => console.log(`   - ${m}`))
}

console.log('\n🛠️ Database Tooling & SQL Scripts:')
console.log('   - db/diagnostic.sql: Read-only live database diagnostic query')
console.log('   - db/setup_supabase.sql: Idempotent consolidated master setup script')
console.log('   - db/verify_setup.sql: Post-deployment verification audit script')
console.log('   - db/seed.sql: Optional sample data for testing')
console.log('====================================================')
