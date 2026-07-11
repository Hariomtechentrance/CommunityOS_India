// Seeds demo Users (with a location profile: area/city/state/pincode) across
// a representative spread of Indian states and metro cities, so geographic
// diversity can actually be tested - area text search works today; map/nearby
// search lights up once a real Google Maps key is configured, since these are
// seeded without lat/lng.
//
// Rewritten after the "My Area" no-login Profile model was merged into the
// authenticated User - these are now real Users (with demo phone numbers),
// not anonymous profiles.
//
// Safe to re-run: skips seeding if demo data already exists.
//
// Usage: node scripts/seed-demo-areas.js

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const CITIES = [
  { area: 'Mumbai Andheri', state: 'Maharashtra', city: 'Mumbai', pincode: '400058', name: 'Rohan P. (Demo)' },
  { area: 'Delhi Connaught Place', state: 'Delhi', city: 'Delhi', pincode: '110001', name: 'Neha S. (Demo)' },
  { area: 'Bengaluru Indiranagar', state: 'Karnataka', city: 'Bengaluru', pincode: '560038', name: 'Kiran M. (Demo)' },
  { area: 'Chennai Adyar', state: 'Tamil Nadu', city: 'Chennai', pincode: '600020', name: 'Priya R. (Demo)' },
  { area: 'Kolkata Salt Lake', state: 'West Bengal', city: 'Kolkata', pincode: '700064', name: 'Sourav D. (Demo)' },
  { area: 'Hyderabad Gachibowli', state: 'Telangana', city: 'Hyderabad', pincode: '500032', name: 'Anitha K. (Demo)' },
  { area: 'Pune Kothrud', state: 'Maharashtra', city: 'Pune', pincode: '411038', name: 'Sameer J. (Demo)' },
  { area: 'Ahmedabad Navrangpura', state: 'Gujarat', city: 'Ahmedabad', pincode: '380009', name: 'Kavita P. (Demo)' },
  { area: 'Jaipur Malviya Nagar', state: 'Rajasthan', city: 'Jaipur', pincode: '302017', name: 'Vikram S. (Demo)' },
  { area: 'Lucknow Gomti Nagar', state: 'Uttar Pradesh', city: 'Lucknow', pincode: '226010', name: 'Ritu V. (Demo)' },
  { area: 'Chandigarh Sector 22', state: 'Punjab/Haryana', city: 'Chandigarh', pincode: '160022', name: 'Gurpreet S. (Demo)' },
  { area: 'Bhopal Arera Colony', state: 'Madhya Pradesh', city: 'Bhopal', pincode: '462016', name: 'Manish T. (Demo)' },
  { area: 'Patna Boring Road', state: 'Bihar', city: 'Patna', pincode: '800001', name: 'Ashok K. (Demo)' },
  { area: 'Guwahati Zoo Road', state: 'Assam', city: 'Guwahati', pincode: '781005', name: 'Bijoya N. (Demo)' },
  { area: 'Kochi Marine Drive', state: 'Kerala', city: 'Kochi', pincode: '682031', name: 'Divya M. (Demo)' },
  { area: 'Nashik Satpur', state: 'Maharashtra', city: 'Nashik', pincode: '422007', name: 'Amit K. (Demo)' },
];

const POST_TEMPLATES = (cityLabel) => [
  {
    kind: 'UPDATE',
    title: `Road maintenance near ${cityLabel}`,
    description: 'Main road closed for repairs this week, expect delays during peak hours.',
  },
  {
    kind: 'SHOP',
    title: `New grocery store opened in ${cityLabel}`,
    description: 'Fresh produce, home delivery available, opened this month.',
    location: `Main market, ${cityLabel}`,
  },
  {
    kind: 'SPORTS_INVITE',
    title: 'Looking for a badminton partner',
    description: 'Evenings after 6pm, casual play, all skill levels welcome.',
    sportName: 'Badminton',
  },
];

async function main() {
  const alreadySeeded = await prisma.user.findFirst({
    where: { name: { endsWith: '(Demo)' } },
  });
  if (alreadySeeded) {
    console.log('Demo area data already exists - skipping (safe re-run).');
    return;
  }

  for (const city of CITIES) {
    const user = await prisma.user.create({
      data: {
        phone: `+91-demo-${city.city.toLowerCase()}-${Date.now()}`,
        name: city.name,
        area: city.area,
        city: city.city,
        state: city.state,
        pincode: city.pincode,
      },
    });

    for (const template of POST_TEMPLATES(city.area)) {
      await prisma.areaPost.create({
        data: {
          userId: user.id,
          area: city.area,
          kind: template.kind,
          title: template.title,
          description: template.description,
          location: template.location,
          sportName: template.sportName,
          imageUrls: [],
        },
      });
    }

    console.log(`Seeded ${city.area} (${city.state}) - user ${user.id}`);
  }

  console.log(`\nDone. ${CITIES.length} cities seeded, ${CITIES.length * 3} posts total.`);
  console.log('Test by logging in, completing your location profile with one of these area names exactly:');
  CITIES.forEach((c) => console.log(`  - ${c.area}`));
}

main()
  .catch((e) => {
    console.error(e);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
