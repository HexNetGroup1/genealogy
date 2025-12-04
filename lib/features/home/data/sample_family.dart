import '../models/family_member.dart';

const List<FamilyMember> sampleFamily = [
  FamilyMember(
    id: 'alexei',
    fullName: 'Aleksei Zhezhir',
    lifeSpan: '1921–1998',
    role: 'Founder of the archive',
    story:
        'Aleksei documented the family history in notebooks during long train rides. '
        'After World War II he dedicated every spring to visiting relatives and recording their stories.',
    highlights: ['War veteran', 'Amateur historian'],
    childrenIds: ['boris', 'daria'],
  ),
  FamilyMember(
    id: 'boris',
    fullName: 'Boris Zhezhir',
    lifeSpan: '1948–2012',
    role: 'Cartographer',
    story:
        'Boris digitized Aleksei\'s notes and built the first map that connected each branch '
        'of the Zhezhir family. He believed a good map helps people feel at home anywhere.',
    highlights: ['Mapped 136 relatives', 'Loved mountain hikes'],
    childrenIds: ['ivan', 'nina'],
  ),
  FamilyMember(
    id: 'daria',
    fullName: 'Daria Zhezhir',
    lifeSpan: '1953–',
    role: 'Storyteller',
    story:
        'Daria turned bedtime stories into full length family chronicles. She is still the person '
        'everyone calls when they need to verify a detail about the family tree.',
    highlights: ['Hosts summer reunions'],
    childrenIds: ['olga'],
  ),
  FamilyMember(
    id: 'ivan',
    fullName: 'Ivan Zhezhir',
    lifeSpan: '1973–',
    role: 'Archivist',
    story:
        'Ivan rescued boxes of tapes from a flooded basement and digitized every recording. '
        'He now curates the Supabase collections for the genealogy project.',
    highlights: ['Keeps analog tape collection'],
    childrenIds: ['mira'],
  ),
  FamilyMember(
    id: 'nina',
    fullName: 'Nina Zhezhir',
    lifeSpan: '1978–',
    role: 'Researcher',
    story:
        'Nina interviews distant cousins via video calls. She marks every conversation with tags '
        'so future generations can find topics quickly.',
    highlights: ['Metadata expert'],
  ),
  FamilyMember(
    id: 'olga',
    fullName: 'Olga Kuznetsova',
    lifeSpan: '1982–',
    role: 'Documentary photographer',
    story:
        'Olga combines film photography with oral history. Her series "Homes of the Zhezhirs" '
        'sparked the idea for this mobile app.',
    highlights: ['Shoots on 35mm and instant film'],
    childrenIds: ['tim'],
  ),
  FamilyMember(
    id: 'mira',
    fullName: 'Mira Zhezhir',
    lifeSpan: '2001–',
    role: 'Product designer',
    story:
        'Mira sketches every prototype inside this project. She pushes for playful interactions '
        'so that the family tree feels alive.',
    highlights: ['Lead designer for the app'],
  ),
  FamilyMember(
    id: 'tim',
    fullName: 'Tim Yashin',
    lifeSpan: '2008–',
    role: 'Junior researcher',
    story:
        'Tim is obsessed with drones and records aerial videos of each family hometown. '
        'He annotates every clip with facts that Olga collects.',
    highlights: ['Drone pilot', 'Future data scientist'],
  ),
];
