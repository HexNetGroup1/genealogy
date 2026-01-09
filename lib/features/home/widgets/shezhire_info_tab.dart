import 'package:flutter/material.dart';

class ShezhireInfoTab extends StatelessWidget {
  const ShezhireInfoTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      children: [
        const SizedBox(height: 20),
        Text(
          'Шежіре дегеніміз не?',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1B5E20),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        
        _InfoCard(
          title: 'Мағынасы',
          content: 'Шежіре (араб.: شجرة‎ — «бұтақ», «ағаш») — қазақ халқының шығу тегін, таралуын баяндайтын тарихи дерек. Ол атадан балаға мирас болып қалатын ауызша және жазбаша шежіре ретінде сақталып келген.',
          icon: Icons.auto_stories_rounded,
        ),
        
        _InfoCard(
          title: 'Жеті ата',
          content: 'Қазақ салты бойынша әрбір адам өзінің жеті атасын білуі тиіс. Бұл тек туыстықты білу ғана емес, сонымен қатар қан тазалығын сақтаудың және ұлттық генетиканың негізі.',
          icon: Icons.groups_rounded,
        ),
        
        _InfoCard(
          title: 'Маңыздылығы',
          content: '«Жеті атасын білмеген жетесіз» — бұл сөз қазақ қоғамында тегін білудің қаншалықты маңызды екенін білдіреді. Шежіре арқылы біз ата-бабаларымыздың ерлігін, тарихын және салт-дәстүрін білеміз.',
          icon: Icons.workspace_premium_rounded,
        ),
        
        const SizedBox(height: 24),
        
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F8E9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFC8E6C9)),
          ),
          child: const Column(
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFF388E3C)),
              SizedBox(height: 12),
              Text(
                'Бұл қосымша сізге өз шежіреңізді сақтауға және келесі ұрпаққа жеткізуге көмектеседі.',
                style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;

  const _InfoCard({
    required this.title,
    required this.content,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.withAlpha(40)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF2E7D32), size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
