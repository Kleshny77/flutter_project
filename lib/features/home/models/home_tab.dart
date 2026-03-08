enum HomeTab {
  schedule('Расписание', 'assets/images/home/calendar_tab.png'),
  pharmacy('Аптечка', 'assets/images/home/aptechka_tab.png'),
  stats('Статистика', 'assets/images/home/statistics_tab.png');

  const HomeTab(this.title, this.assetPath);

  final String title;
  final String assetPath;
}
