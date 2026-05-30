// Lists every Arabic word currently mapped in psl_video_service.dart,
// grouped by English target.
const fs = require('fs');
const src = fs.readFileSync(
  __dirname + '/../lib/src/features/communicate/data/psl_video_service.dart',
  'utf8'
);
const start = src.indexOf('const Map<String, String> _arabicToEnglish');
const end = src.indexOf('};', start);
const block = src.slice(start, end);
const re = /'([^']+)':\s*['"]([^'"]+)['"]/g;
const ar2en = {};
let m;
while ((m = re.exec(block))) ar2en[m[1]] = m[2];

const byEn = {};
for (const [ar, en] of Object.entries(ar2en)) {
  (byEn[en] = byEn[en] || []).push(ar);
}

const sets = [
  ['Numbers', /^(one|two|three|four|five|six|seven|eight|nine|ten|a hundred|one hundred|five hundred|a thousand|one thousand|ten thousand|one lakh|one crore)$/],
  ['Family / People', /^(father|papa|dad|daddy|mother|mom|mommy|mama|brother|sister|son|daughter|boy|girl|family|friend|husband|wife|woman|lady|female|male|feminine|masculine|gentleman|old man|old woman|elderly man|elderly woman|manly|people|he|she|we|they|me|this|that|here|there|who|whom|whose|what|when|maternal grandfather|maternal grandmother|paternal grandfather|paternal grandmother|brother's son|brother's daughter|brother's wife|sister's son|sister's daughter)$/],
  ['Time / Calendar', /^(day|night|morning|evening|noon|afternoon|today|tomorrow|day after tomorrow|yesterday|week|month|year|hour|half hour|half an hour|time|time off|holiday|monday|tuesday|wednesday|thursday|friday|saturday|sunday|january|february|june|july|september|october|november|december|before|previous|early|next|again|always|forever|ever|every|annual|annually|yearly|monthly|summer|winter|autumn)$/],
  ['Weather / Nature', /^(weather|hot|cold|warm|rain|rainfall|raining|rainy|storm|stormy|hailstorm|wind storm|rainbow|sun|sunny|moon|stars|sky)$/],
  ['Places', /^(house|home|bathroom|toilet|washroom|hospital|school|classroom|college|university|library|mosque|masjid|shrine|graveyard|cemetery|market|shop|bookshop|bookstore|hotel|restaurant|museum|garden|park|forest|jungle|zoo|river|sea|ocean|mountain|mountains|mountainous|hills|hilly|road|street|streets|village|city|country|province|provincial|continent|world|area|place|location|locality|residence|earth|airport|airfield|hostel|factory|office|workplace|bank|post office|stadium|fort|fortress|castle|tomb|bus stop|bus stand|bus station|busstop|railway station|train station)$/],
  ['Transport', /^(car|bus|motorbike|motorcycle|rickshaw|van|tractor|airplane|aeroplane|aircraft|fighter jet|military aircraft|marine|transportation|donkey carriage|donkey cart|donkey chariot)$/],
  ['Food / Drink', /^(bread|rice|beef|cow meat|mutton|goat meat|chicken meat|egg|milk|yogurt|butter|sugar|salt|flour|tea|coffee|juice|beverage|soup|apple|banana|bananas|mango|mangos|mangoes|grape|grapes|pomegranate|watermelon|melon|pineapple|strawberry|guava|apricot|lemon|orange|fruit|fruits|vegetables|potato|tomato|onion|garlic|ginger|carrot|cauliflower|cucumber|spinach|okra|lady finger|brinjal|aubergine|eggplant|radish|coriander|parsley|green chilli|red chilli|sugar cane|sugarcane|noodles|burger|cake|biscuit|biscuits|cookie|cookies|toffee|candy|sweets|confectionery|ice cream|icecream|jambul|jamun|java plum|coconut|lentil|lentils|feast|naan|chapati|roti|samosa|kebab|chana chaat|dahi bhale|dahi bhally|chicken)$/],
  ['Animals', /^(dog|doggy|cat|cow|horse|goat|sheep|donkey|camel|lion|lioness|tiger|elephant|monkey|rabbit|bunny|hare|rat|mouse|alligator|crocodile|fish|hen|rooster|cock|duck|parrot|pigeon|sparrow|owl|peacock|crow|raven|frog|toad|tortoise|turtle|giraffe)$/],
  ['Colors', /^(red|blue|green|greenish|yellow|yellowish|black|white|brown|pink|purple|grey|gray|gold|golden|silver|color|colour|complexion|pale)$/],
  ['Health', /^(ill|unwell|sick|ache|pain|medication|medicine|ambulance|emergency|physician|therapist)$/],
  ['Feelings / States', /^(happy|happiness|unhappy|sad|saddened|saddening|sadness|sorrow|sorrowful|worry|worried|anxiety|anxious|anger|furious|hate|hatred|loathe|loathing|liked|liking|fondness|joy|fun|fearsome|frightening|scary|terrifying|horrifying|shy|shyness|ashamed|shame|embarrassed|embarrassing|embarrassment|humiliated|humiliation|insult|insulted|proud|pride|arrogant|arrogance|greed|greedy|miser|pinchpenny|stingy|cunning|clever|intelligent|interested|interesting|important|honest|honestly|honesty|honourable|decent|obedient|obedience|obstinacy|stubborn|stubbornness|punctual|punctuality|responsible|responsibility|responsibly|respect|respectful|well mannered|smart|stupid|idiot|idiotic|fool|foolish|rascal|scoundrel|bully|cruel|cruelty|brutal|brutality|merciless|mercy|enemy|enmity|animosity|hostility|rivalry|competition|competitiveness|selfish|selfishness|calm|calmness|tranquility|peace of mind|relax|relaxed|relaxing|rested|resting|restless|restlessness|beautiful|gorgeous|beauty|handsome|pleasant|pleasing|delightful|good|great|nice|rich|wealthy|wealth|poor|impoverished|poverty|penniless|busy|preoccupied|idle|lazy|laziness|lazily|work-shy|work dodger|workshy|weak|weaker|weakness|fit|fitness|cool|chill|chilled|chilly|full|noise|noisy|nonsense|pointless|futile|senseless|absurd|thirst|thirsty|hungry)$/],
  ['Religion', /^(god|allah|prophet|apostle|iblis|satan|devil|angel|paradise|heaven|hell|faith|belief|blessing|sin|fasting|charity|zakat|pilgrimage|hajj|namaz|salat|prayer|fajr|fajar|zuhr|asr|maghrib|isha|quran|qur'an|holy qur'an|holy quran|koran|quranic|hadith|kalmah|imam|monotheism|monotheistic|muslim|muslims|christian|christianity|christians|hindu|jihad|lunar|solar)$/],
  ['School / Things', /^(book|textbook|newspaper|notebook|diary|pen|pencil|ballpoint|ballpoint pen|ball point|ball point pen|ink|paper|eraser|sharpener|stapler|desk|chair|cupboard|closet|door|bell|meter rod|calculator|calendar|schedule|timetable|bag|picture|photo|photograph|image|drama|drama serial|drama series|movie|cartoon|cartoonish|spectacle|camera|shoe|shoes|boots|slippers|sandals|dupatta|scarf|shirt|kameez|pajamas|jeans|jeans pants|denim pants|frock)$/],
  ['School / Work', /^(student|teacher|professor|instructor|tutor|apprentice|exam|examination|test|result|question|answer|answered|answering|knowledge|knowledgeable|wise|illiteracy|illiterate|uneducated|science|scientific|math|maths|mathematics|art|arts|poet|poetess|poetry|story|tale|word|words|urdu|job|work|business|loan|debt|bribe|bribery|fraud|theft|thief|robber|robbery|snatch|snatched|dacoit|gangster|rebel|rebellion|rebelliousness|revolt|mutiny|government|governmental|govt|prime minister|chairman|chairwoman|chairperson|cheif|principal|principle|attorney|lawyer|law|legal|policeman|police man|police officer|police woman|sepoy|farmer|irrigate|irrigation|plants|tree|flower|leaf|servant|maid|watchman|laborer|labourer)$/],
  ['Verbs / Actions', /^(give|given|gave|take|wait|waiting|walk|walking|stroll|wake|wake up|awake|awaken|awakened|waking up|hear|speak|talk|conversation|listen|help|helpful|assistance|aid|benefit|beneficial|useful|usefulness|useless|utility|utilize|use|usage|make|made|build|built|construct|constructed|manufacture|manufactured|create|created|creator|initiate|start|started|starting|begin|began|begins|begun|beginning|final|first|complete|completed|include|included|including|inclusive|contained|containing|contains|consist|find|search|searched|searching|loss|liberate|liberated|freed|freedom|independence|victory|conquest|fail|failed|failure|succeed|succeeded|success|successful|achievement|effort|endeavor|hardship|difficult|difficulty|easy|ease|easily|easiness|hardwork|hard work|hard worker|hardworking|workout|exercise|forgive|forgiveness|pardon|amnesty|apology|apologize|approve|approval|consent|permission|pledge|pledged|promise|promised|preach|preaching|preachment|punish|punishment|penalty|protected|protection|safe|safety|secure|security|security guard)$/],
  ['Misc', /^(in|at|to|from|with|and|or|ahead|forward|away|far|far away|near|nearby|middle|center|centre|between|along|inside|front|new|old|young|many|few|some|all|desire|wish|hope|luck|fate|hurry|haste|quick|quickly|rapidly|speedy|swiftly|sudden|suddenly|surely|definitely|perhaps|maybe|indeed|duty|task|attention|focus|consider|consideration|suggestion|advice|information|population|social|society|ethnic|ethnicity|historic places|historic sites|vote|voting|election|elections|charcoal|coal|drink|air)$/],
  ['Countries', /^(saudi|saudi arabia|saudi arabian|iran|iranian|iraq|iraqi|india|indian|hindustan|bangladesh|afghanistan|australia|australian|china|japan|japanese|england|america|united states of america|usa|kuwait|dubai)$/],
];

let totalShown = 0;
const usedEn = new Set();
for (const [name, re] of sets) {
  const found = {};
  for (const en of Object.keys(byEn)) {
    if (usedEn.has(en)) continue;
    if (re.test(en)) {
      found[en] = byEn[en];
      usedEn.add(en);
    }
  }
  const keys = Object.keys(found).sort();
  if (!keys.length) continue;
  console.log('\n=== ' + name + ' (' + keys.length + ' clips) ===');
  for (const en of keys) {
    console.log('  ' + en + '  →  ' + found[en].join(' / '));
    totalShown++;
  }
}

const leftover = Object.keys(byEn).filter((e) => !usedEn.has(e)).sort();
if (leftover.length) {
  console.log('\n=== Other (' + leftover.length + ' clips) ===');
  for (const en of leftover) {
    console.log('  ' + en + '  →  ' + byEn[en].join(' / '));
  }
}
console.log('\n--- shown: ' + totalShown + ' / ' + Object.keys(byEn).length + ' clips ---');
