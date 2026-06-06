class BabyWeekData {
  final int week;
  final String size;
  final String fruit;
  final String description;
  final String imageUrl;

  const BabyWeekData({
    required this.week,
    required this.size,
    required this.fruit,
    required this.description,
    required this.imageUrl,
  });
}

// Using Wikimedia Commons public domain fetal development images
const List<BabyWeekData> babyWeeklyData = [
  BabyWeekData(
    week: 4,
    size: '2 mm',
    fruit: 'Poppy seed',
    description: 'A tiny cluster of cells is forming. The neural tube that becomes the brain and spine is developing.',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/73/Week_4_-_140_%28cropped%29.jpg/320px-Week_4_-_140_%28cropped%29.jpg',
  ),
  BabyWeekData(
    week: 5,
    size: '4 mm',
    fruit: 'Sesame seed',
    description: 'The heart begins to beat! Tiny arm and leg buds are starting to form.',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/63/Illustration_of_human_fetus%2C_week_5.jpg/320px-Illustration_of_human_fetus%2C_week_5.jpg',
  ),
  BabyWeekData(
    week: 6,
    size: '6 mm',
    fruit: 'Lentil',
    description: 'The heart is beating about 100 times per minute. Eyes and ears are starting to form.',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/35/Illustration_of_human_fetus%2C_week_6.jpg/320px-Illustration_of_human_fetus%2C_week_6.jpg',
  ),
  BabyWeekData(
    week: 7,
    size: '1.3 cm',
    fruit: 'Blueberry',
    description: 'Baby\'s brain is growing rapidly. Hands and feet are forming, though fingers are webbed.',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/55/Illustration_of_human_fetus%2C_week_7.jpg/320px-Illustration_of_human_fetus%2C_week_7.jpg',
  ),
  BabyWeekData(
    week: 8,
    size: '1.6 cm',
    fruit: 'Kidney bean',
    description: 'All essential organs have begun forming. Baby is starting to look more human with distinct facial features.',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Illustration_of_human_fetus%2C_week_8.jpg/320px-Illustration_of_human_fetus%2C_week_8.jpg',
  ),
  BabyWeekData(
    week: 9,
    size: '2.3 cm',
    fruit: 'Cherry',
    description: 'Baby can now move! Tiny muscles are developing and the embryo officially becomes a fetus.',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/72/Illustration_of_human_fetus%2C_week_9.jpg/320px-Illustration_of_human_fetus%2C_week_9.jpg',
  ),
  BabyWeekData(
    week: 10,
    size: '3.1 cm',
    fruit: 'Strawberry',
    description: 'Baby\'s organs are formed and now just need to grow! Tiny fingernails are developing.',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4a/Illustration_of_human_fetus%2C_week_10.jpg/320px-Illustration_of_human_fetus%2C_week_10.jpg',
  ),
  BabyWeekData(
    week: 12,
    size: '5.4 cm',
    fruit: 'Lime',
    description: 'Baby can open and close fingers. Reflexes are developing and kidneys start producing urine.',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/Illustration_of_human_fetus%2C_week_12.jpg/320px-Illustration_of_human_fetus%2C_week_12.jpg',
  ),
  BabyWeekData(
    week: 16,
    size: '11.6 cm',
    fruit: 'Avocado',
    description: 'Baby\'s eyes can move, and they may suck their thumb. You might start feeling movements soon!',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/df/Illustration_of_human_fetus%2C_week_16.jpg/320px-Illustration_of_human_fetus%2C_week_16.jpg',
  ),
  BabyWeekData(
    week: 20,
    size: '25.6 cm',
    fruit: 'Banana',
    description: 'Halfway there! Baby can hear sounds and swallow. You can feel kicks and movements clearly.',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c8/Illustration_of_human_fetus%2C_week_20.jpg/320px-Illustration_of_human_fetus%2C_week_20.jpg',
  ),
  BabyWeekData(
    week: 24,
    size: '30 cm',
    fruit: 'Corn',
    description: 'Baby\'s face is fully formed and tiny taste buds are developing. Lungs are maturing.',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7d/Illustration_of_human_fetus%2C_week_24.jpg/320px-Illustration_of_human_fetus%2C_week_24.jpg',
  ),
  BabyWeekData(
    week: 28,
    size: '37.6 cm',
    fruit: 'Eggplant',
    description: 'Baby opens eyes for the first time and can blink! Brain is developing rapidly.',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f3/Illustration_of_human_fetus%2C_week_28.jpg/320px-Illustration_of_human_fetus%2C_week_28.jpg',
  ),
  BabyWeekData(
    week: 32,
    size: '42.4 cm',
    fruit: 'Squash',
    description: 'Baby is practicing breathing movements. Gaining weight fast — about half a pound per week!',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/Illustration_of_human_fetus%2C_week_32.jpg/320px-Illustration_of_human_fetus%2C_week_32.jpg',
  ),
  BabyWeekData(
    week: 36,
    size: '47.4 cm',
    fruit: 'Romaine lettuce',
    description: 'Baby is almost ready! Most organ systems are mature. Baby is in position for birth.',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/36/Illustration_of_human_fetus%2C_week_36.jpg/320px-Illustration_of_human_fetus%2C_week_36.jpg',
  ),
  BabyWeekData(
    week: 40,
    size: '51 cm',
    fruit: 'Watermelon',
    description: 'Full term! Baby could arrive any day. Get ready for the most amazing moment of your life!',
    imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Illustration_of_human_fetus%2C_week_40.jpg/320px-Illustration_of_human_fetus%2C_week_40.jpg',
  ),
];

BabyWeekData getBabyDataForWeek(int week) {
  // Find the closest week in our data
  BabyWeekData result = babyWeeklyData.first;
  for (final data in babyWeeklyData) {
    if (data.week <= week) {
      result = data;
    } else {
      break;
    }
  }
  return result;
}
