/// Вымышленные люди и переписки для превью приложения.
/// Все id начинаются с 9001, у настоящих пользователей таких id нет.

class DemoMessage {
  const DemoMessage(
    this.text, {
    this.mine = false,
    this.minutesAgo,
    this.daysAgo = 0,
    this.hour = 12,
    this.minute = 0,
  });

  final String text;
  final bool mine; // true: написала я, false: написал собеседник

  /// Для свежих сообщений: «столько-то минут назад»
  final int? minutesAgo;

  /// Для старых сообщений: сколько дней назад и в какое время
  final int daysAgo;
  final int hour;
  final int minute;

  DateTime when(DateTime now) {
    if (minutesAgo != null) {
      return now.subtract(Duration(minutes: minutesAgo!)).toUtc();
    }
    return DateTime(now.year, now.month, now.day - daysAgo, hour, minute)
        .toUtc();
  }
}

class DemoPerson {
  const DemoPerson({
    required this.id,
    required this.photo,
    required this.name,
    required this.phone,
    required this.status,
    required this.messages,
    this.unread = 0,
    this.replies = const [],
  });

  final int id;

  /// Номер фото: assets/demo/avatar_01.jpg, avatar_02.jpg и так далее
  final int photo;
  final String name;
  final String phone;
  final String status;
  final List<DemoMessage> messages;

  /// Сколько последних входящих сообщений остаются непрочитанными
  final int unread;

  /// Чем собеседник отвечает, когда ему пишут (если пусто, берутся общие)
  final List<String> replies;

  String get asset =>
      'assets/demo/avatar_${photo.toString().padLeft(2, '0')}.${DemoData.photoExtension}';
}

class DemoData {
  /// Если твои фото в формате png, поменяй здесь на 'png'
  static const photoExtension = 'jpg';

  static const firstId = 9001;

  static bool isDemo(int id) => id >= firstId;

  static DemoPerson? byId(int id) {
    for (final p in people) {
      if (p.id == id) return p;
    }
    return null;
  }

  static const genericReplies = [
    'Привет! 👋',
    'Отлично, договорились 👍',
    'Ха-ха, понял 😄',
    'Сейчас гляну и отвечу',
    'Спасибо! 🙏',
    'Классная идея ✨',
    'Позже наберу, ок?',
  ];

  static const people = [
    // Только что написали: непрочитанные
    DemoPerson(
      id: 9001,
      photo: 1,
      name: 'Максим Громов',
      phone: '+996700900001',
      status: 'На связи 24/7 🚀',
      unread: 2,
      replies: ['Принял, скоро вернусь с правками 🎨', 'Супер, спасибо!'],
      messages: [
        DemoMessage('Привет! Как продвигается проект?',
            mine: true, daysAgo: 3, hour: 10, minute: 15),
        DemoMessage('Всё идёт по плану, на днях покажу результат',
            daysAgo: 3, hour: 10, minute: 40),
        DemoMessage('Отправил обновлённые макеты дизайна! 🎨', minutesAgo: 14),
        DemoMessage('Посмотри, когда будет минутка 🙌', minutesAgo: 3),
      ],
    ),
    DemoPerson(
      id: 9008,
      photo: 8,
      name: 'Алина Смирнова',
      phone: '+996700900008',
      // Длинный статус: проверка переноса строк
      status:
          'Product Designer & UI Developer ✨ Всегда на связи для интересных проектов!',
      unread: 3,
      messages: [
        DemoMessage('Привет! Видела твоё портфолио, очень круто 🔥',
            minutesAgo: 55),
        DemoMessage('Есть небольшой проект по мобильному приложению',
            minutesAgo: 52),
        DemoMessage('Если интересно, давай созвонимся на этой неделе 📞',
            minutesAgo: 9),
      ],
    ),
    DemoPerson(
      id: 9002,
      photo: 2,
      name: 'Екатерина Волкова',
      phone: '+996700900002',
      status: 'Кофе и код ☕',
      unread: 1,
      replies: ['Тогда до встречи! 😊', 'Беру тебе капучино ☕'],
      messages: [
        DemoMessage('Ты сегодня в офисе?',
            mine: true, daysAgo: 1, hour: 18, minute: 5),
        DemoMessage('Нет, работаю из дома 🏡', daysAgo: 1, hour: 18, minute: 12),
        DemoMessage('Встретимся в кафе в 18:00? ☕', minutesAgo: 27),
      ],
    ),

    // Сегодня, уже прочитано
    DemoPerson(
      id: 9010,
      photo: 10,
      name: 'Мама ❤️',
      phone: '+996700900010',
      status: 'Не забудь покушать 🍲',
      replies: ['Люблю тебя 🥰', 'Одевайся теплее!'],
      messages: [
        DemoMessage('Ты поел? 🍲', minutesAgo: 180),
        DemoMessage('Да, мам, всё хорошо 😄', mine: true, minutesAgo: 170),
        DemoMessage('Молодец 🥰 Позвони вечером', minutesAgo: 165),
      ],
    ),

    // Вчера и позавчера
    DemoPerson(
      id: 9003,
      photo: 3,
      name: 'Артём Николаев',
      phone: '+996700900003',
      status: 'В отпуске 🌴',
      messages: [
        DemoMessage('Слушай, не поможешь разобраться с отчётом?',
            daysAgo: 2, hour: 15, minute: 2),
        DemoMessage('Конечно, скинь файл',
            mine: true, daysAgo: 2, hour: 15, minute: 20),
        DemoMessage('Спасибо за помощь! 🙏', daysAgo: 1, hour: 21, minute: 3),
      ],
    ),
    DemoPerson(
      id: 9004,
      photo: 4,
      name: 'Ольга Ковалева',
      phone: '+996700900004',
      status: 'Люблю горы ⛰️',
      messages: [
        DemoMessage('Скинь фото с похода 📸',
            daysAgo: 4, hour: 19, minute: 0),
        DemoMessage('Сейчас найду, их там штук сто 😄',
            mine: true, daysAgo: 4, hour: 19, minute: 30),
        DemoMessage('Жду, очень хочу посмотреть ⛰️',
            daysAgo: 4, hour: 20, minute: 10),
      ],
    ),

    // Давно
    DemoPerson(
      id: 9005,
      photo: 5,
      name: 'Дамир Сатыбалдиев',
      phone: '+996700900005',
      status: 'Работаю, не отвлекайте 🎧',
      messages: [
        DemoMessage('Когда сможем созвониться по поводу релиза?',
            daysAgo: 8, hour: 11, minute: 5),
        DemoMessage('Давай в пятницу после обеда',
            mine: true, daysAgo: 8, hour: 11, minute: 30),
        DemoMessage('Договорились, до пятницы 👍',
            daysAgo: 8, hour: 11, minute: 41),
        DemoMessage('Отлично, жду 🤝', mine: true, daysAgo: 8, hour: 11, minute: 50),
      ],
    ),
    DemoPerson(
      id: 9006,
      photo: 6,
      name: 'Айгуль Токтосунова',
      phone: '+996700900006',
      status: 'Всё будет хорошо ✨',
      messages: [
        DemoMessage('С днём рождения! Желаю счастья, здоровья и побольше ярких идей 🎂✨',
            daysAgo: 12, hour: 9, minute: 0),
        DemoMessage('Спасибо тебе огромное ❤️',
            mine: true, daysAgo: 12, hour: 9, minute: 45),
      ],
    ),
    DemoPerson(
      id: 9007,
      photo: 7,
      name: 'Игорь Петров',
      phone: '+996700900007',
      status: 'Ремонт, стройка и немного кода 🛠️',
      messages: [
        DemoMessage('Привет! Ты нашёл того мастера по плитке?',
            mine: true, daysAgo: 19, hour: 13, minute: 10),
        DemoMessage('Да, скину контакты вечером 🛠️',
            daysAgo: 19, hour: 13, minute: 25),
        DemoMessage('Благодарю, свяжусь завтра',
            mine: true, daysAgo: 19, hour: 13, minute: 31),
      ],
    ),

    // Очень давно и очень длинное имя: проверка переноса строк
    DemoPerson(
      id: 9009,
      photo: 9,
      name: 'Александр Константинович Вознесенский-Ростовцев',
      phone: '+996700900009',
      status: 'Отвечу в рабочее время',
      messages: [
        DemoMessage('Добрый день! Направляю вам договор на подпись',
            daysAgo: 33, hour: 10, minute: 0),
        DemoMessage('Получил, посмотрю до конца недели',
            mine: true, daysAgo: 33, hour: 10, minute: 20),
        DemoMessage('Благодарю за оперативность 🙂',
            daysAgo: 33, hour: 10, minute: 24),
      ],
    ),
  ];
}
