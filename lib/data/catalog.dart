// Каталог полів Vespr. Джерело: документ «Vespr — теги, питання і логіка аналізу».
// Id англійською (snake_case), назви для людей — окремо, щоб їх можна було міняти і перекладати.

class Question {
  final String id, text, dim;
  final bool def, always;
  const Question(this.id, this.text, this.dim, {this.def = false, this.always = false});
}

// Три базові питання є завжди: «Як загалом?», «Наскільки тобі було добре?», «Наскільки дбали про тебе?»
const sexQuestions = <Question>[
  Question('sx_overall', 'Як загалом?', 'Якір', always: true),
  Question('sx_pleasure', 'Наскільки тобі було добре?', 'Тіло', always: true),
  Question('sx_finish', 'Наскільки ти задоволена фіналом?', 'Тіло', def: true),
  Question('sx_chem', 'Наскільки збіглась хімія?', 'Тіло'),
  Question('sx_care', 'Наскільки дбали про тебе?', 'Турбота', always: true),
  Question('sx_heard', 'Наскільки тебе почули?', 'Турбота', def: true),
  Question('sx_after', 'Наскільки тепло було після?', 'Турбота'),
  Question('sx_fore', 'Наскільки вистачало прелюдії?', 'Темп', def: true),
  Question('sx_pace', 'Наскільки тобі підходив темп?', 'Темп', def: true),
  Question('sx_length', 'Наскільки підходила тривалість?', 'Темп'),
  Question('sx_ask', 'Наскільки легко було сказати, чого хочеш?', 'Розмова'),
  Question('sx_react', 'Наскільки він реагував на твої підказки?', 'Розмова'),
  Question('sx_self', 'Наскільки ти могла бути собою?', 'Свобода', def: true),
  Question('sx_safe', 'Наскільки ти почувалась у безпеці?', 'Свобода'),
  Question('sx_relax', 'Наскільки вдалось розслабитись і не думати, як ти виглядаєш?', 'Свобода'),
  Question('sx_lead', 'Наскільки ти сама вела?', 'Свобода'),
];

const partnerQuestions = <Question>[
  Question('pt_pull', 'Наскільки тебе тягне до нього?', 'Тяжіння', def: true),
  Question('pt_desired', 'Наскільки ти почуваєшся поруч бажаною?', 'Тяжіння', def: true),
  Question('pt_hears', 'Наскільки він тебе чує?', 'Повага', def: true),
  Question('pt_limits', 'Наскільки поважає твої межі?', 'Повага', def: true),
  Question('pt_free', 'Наскільки вільно тобі без ревнощів і контролю?', 'Повага'),
  Question('pt_trust', 'Наскільки ти йому довіряєш?', 'Довіра', def: true),
  Question('pt_word', 'Наскільки тримає слово і домовленості?', 'Довіра'),
  Question('pt_steady', 'Наскільки він передбачуваний, без зникань?', 'Довіра'),
  Question('pt_pleasure', 'Наскільки цікавиться твоїм задоволенням?', 'Інтерес', def: true),
  Question('pt_curious', 'Наскільки цікавиться тобою, а не тільки сексом?', 'Інтерес'),
  Question('pt_talk', 'Наскільки цікаво говорити не про секс?', 'Легкість', def: true),
  Question('pt_laugh', 'Наскільки вам смішно разом?', 'Легкість'),
  Question('pt_calm', 'Наскільки спокійно поруч з ним?', 'Легкість'),
  Question('pt_effort', 'Наскільки він вкладається часом і увагою?', 'Інтерес'),
  Question('pt_more', 'Наскільки хочеш більшого з ним?', 'Майбутнє', def: true),
  Question('pt_values', 'Наскільки збігаються ваші цінності?', 'Майбутнє'),
];

const selfQuestions = <Question>[
  Question('sf_want', 'Наскільки ти сама хотіла цієї зустрічі?', 'Ти'),
  Question('sf_energy', 'Скільки в тебе було енергії?', 'Ти'),
  Question('sf_proud', 'Наскільки ти задоволена собою за цей вечір?', 'Ти'),
];

const maxChosen = 10;
final allQuestions = <Question>[...sexQuestions, ...partnerQuestions, ...selfQuestions];
Question? qById(String id) {
  for (final q in allQuestions) {
    if (q.id == id) return q;
  }
  return null;
}

const rateWords = ['', 'жах', 'погано', 'так собі', 'добре', 'вогонь'];
String rateWord(num v) => rateWords[v.round().clamp(1, 5)];

// ---------- Теги-осі ----------
class Opt {
  final String id, label;
  const Opt(this.id, this.label);
}

class TagAxis {
  final String id, group, title;
  final List<Opt> a, b;
  final bool sexOnly;
  const TagAxis(this.id, this.group, this.title, this.a, this.b, {this.sexOnly = false});
  List<Opt> get all => [...a, ...b];
}

const axes = <TagAxis>[
  TagAxis('ax_plan', 'Формат', 'План', [Opt('planned', 'Заплановано')], [Opt('spont', 'Спонтанно')]),
  TagAxis('ax_len', 'Формат', 'Тривалість', [Opt('quick', 'Коротка зустріч')], [Opt('long_eve', 'Цілий вечір')]),
  TagAxis('ax_where', 'Де', 'Чия територія', [Opt('his', 'У нього')], [Opt('mine', 'У мене'), Opt('hotel', 'Готель'), Opt('other', 'Інше')]),
  TagAxis('ax_start', 'Де', 'Початок вечора', [Opt('restaurant', 'Ресторан'), Opt('bar', 'Бар, клуб')], [Opt('neutral', 'Кава, парк'), Opt('straight_home', 'Одразу вдома')]),
  TagAxis('ax_time', 'Коли', 'Час', [Opt('day', 'Вдень, увечері')], [Opt('late', 'Пізно, після 22:00')]),
  TagAxis('ax_talk', 'Перед', 'Розмова', [Opt('talk', 'Довго говорили')], [Opt('notalk', 'Майже не говорили')]),
  TagAxis('ax_alco', 'Перед', 'Алкоголь', [Opt('sober', 'Тверезо')], [Opt('alco1', 'Келих-два'), Opt('alco2', 'Більше')]),
  TagAxis('ax_state', 'Перед', 'Твій стан', [Opt('fresh', 'У ресурсі')], [Opt('tired', 'Втомлена, на нервах')]),
  TagAxis('ax_chat', 'Перед', 'Переписка', [Opt('chat', 'Був флірт')], [Opt('nochat', 'Без флірту')]),
  TagAxis('ax_fore', 'Темп', 'Прелюдія', [Opt('fore', 'Довга прелюдія')], [Opt('nofore', 'Одразу до справи')], sexOnly: true),
  TagAxis('ax_speed', 'Темп', 'Швидкість', [Opt('slow', "Повільно, м'яко")], [Opt('rush', 'Швидко, поспіхом')], sexOnly: true),
  TagAxis('ax_mood', 'Темп', 'Настрій', [Opt('tender', 'Ніжно')], [Opt('passion', 'Пристрасно')], sexOnly: true),
  TagAxis('ax_tone', 'Темп', 'Тон', [Opt('play', 'Грайливо, сміялись')], [Opt('serious', 'Серйозно, зосереджено')], sexOnly: true),
  TagAxis('ax_count', 'Темп', 'Скільки', [Opt('once', 'Один раз')], [Opt('multi', 'Кілька разів')], sexOnly: true),
  TagAxis('ax_light', 'Що робили', 'Світло', [Opt('light', 'При світлі')], [Opt('dark', 'У темряві')], sexOnly: true),
  TagAxis('ax_o_me', 'Фінал', 'Твій оргазм', [Opt('o_me', 'Був оргазм'), Opt('o_multi', 'Кілька оргазмів')], [Opt('o_none_ok', 'Без оргазму, і ок'), Opt('o_none_sad', 'Без оргазму, шкода')], sexOnly: true),
  TagAxis('ax_o_him', 'Фінал', 'Його оргазм', [Opt('o_him', 'У нього був')], [Opt('o_him_no', 'У нього не було')], sexOnly: true),
  TagAxis('ax_real', 'Фінал', 'Справжність', [Opt('real', 'Все справжнє')], [Opt('o_fake', 'Симулювала')], sexOnly: true),
  TagAxis('ax_prot', 'Захист', 'Захист', [Opt('condom', 'Презерватив'), Opt('contra', 'Інша контрацепція')], [Opt('noprot', 'Без захисту')], sexOnly: true),
  TagAxis('ax_body', 'Захист', 'Тіло', [Opt('comfy', 'Комфортно')], [Opt('pain', 'Був дискомфорт')], sexOnly: true),
  TagAxis('ax_said', 'Ти', 'Бажання', [Opt('said', 'Сказала, чого хочу')], [Opt('silent', 'Промовчала')]),
  TagAxis('ax_limit', 'Ти', 'Межі', [Opt('limit', 'Позначила межу')], [Opt('limit_missed', 'Хотіла, але не сказала')]),
  TagAxis('ax_init', 'Ти', 'Ініціатива в ліжку', [Opt('init_me', 'Почала я')], [Opt('init_him', 'Почав він')], sexOnly: true),
  TagAxis('ax_close', 'Після', 'Близькість', [Opt('cuddle', 'Обіймались, говорили')], [Opt('cold', 'Одразу в телефони')]),
  TagAxis('ax_night', 'Після', 'Ніч', [Opt('night', 'Лишилась на ніч')], [Opt('left', 'Поїхала')]),
  TagAxis('ax_text', 'Після', 'Хто написав першим', [Opt('text_me', 'Я')], [Opt('text_him', 'Він')]),
];

class Solo {
  final String group;
  final List<Opt> tags;
  final bool sexOnly;
  const Solo(this.group, this.tags, {this.sexOnly = false});
}

const solos = <Solo>[
  Solo('Що робили', [
    Opt('kiss', 'Багато поцілунків'), Opt('oral_me', 'Оральний для тебе'), Opt('oral_him', 'Оральний для нього'),
    Opt('newpos', 'Нова поза'), Opt('toys', 'Іграшки'), Opt('fantasy', 'Фантазія, рольова гра'),
    Opt('shower', 'Душ разом'), Opt('new', 'Щось уперше'),
  ], sexOnly: true),
  Solo('Ти', [Opt('stop', 'Зупинила те, що не подобалось'), Opt('praise', 'Похвалила те, що сподобалось')]),
  Solo('Тіло', [Opt('period', 'Місячні')]),
];

class TagInfo {
  final String label, group;
  final String? axis;
  final bool sexOnly;
  const TagInfo(this.label, this.group, this.axis, this.sexOnly);
}

final Map<String, TagInfo> tagIndex = () {
  final m = <String, TagInfo>{};
  for (final ax in axes) {
    for (final o in ax.all) {
      m[o.id] = TagInfo(o.label, ax.group, ax.id, ax.sexOnly);
    }
  }
  for (final s in solos) {
    for (final o in s.tags) {
      m[o.id] = TagInfo(o.label, s.group, null, s.sexOnly);
    }
  }
  return m;
}();
String tagLabel(String id) => tagIndex[id]?.label ?? id;

// Чутливе: в експорт іде тільки з окремим перемикачем (разом з критичними прапорцями)
const sensitiveTags = {'noprot', 'pain', 'o_fake'};

// ---------- Прапорці ----------
enum FlagKind { g, r, c }

class Flag {
  final String id, label;
  final FlagKind kind;
  final int weight;
  final List<String> triggers;
  final String? negOpposite;
  const Flag(this.id, this.label, this.kind, this.weight, this.triggers, [this.negOpposite]);
}

const flags = <Flag>[
  Flag('flag_g_asks', 'Питав про межі', FlagKind.g, 1, ['спита', 'пита', 'комфортн', 'зручн', 'чи ок', 'не проти']),
  Flag('flag_g_no', 'Поважав «ні»', FlagKind.g, 1, ['прийняв', 'зрозумів', 'без образ']),
  Flag('flag_g_walk', 'Провів, викликав таксі', FlagKind.g, 1, ['провів', 'довів', 'таксі', 'викликав', 'до хати']),
  Flag('flag_g_listen', 'Слухав, розпитував про мене', FlagKind.g, 1, ['слуха', 'розпит', 'цікавив', 'питав про мене']),
  Flag('flag_g_remember', "Запам'ятав деталі", FlagKind.g, 1, ["запам'ят", "пам'ятав"]),
  Flag('flag_g_ontime', 'Прийшов вчасно', FlagKind.g, 1, ['вчасно', 'хвилина в хвилину', 'раніше мене']),
  Flag('flag_g_paid', 'Заплатив', FlagKind.g, 1, ['заплат', 'розрахув', 'закрив чек', 'угостив']),
  Flag('flag_g_gift', 'Квіти, подарунок', FlagKind.g, 1, ['квіт', 'букет', 'подарун', 'сюрприз']),
  Flag('flag_g_condom', 'Сам подбав про захист', FlagKind.g, 1, ['мав з собою']),
  Flag('flag_g_texts', 'Написав після', FlagKind.g, 1, ['написав', 'добралась', 'вранці написав']),
  Flag('flag_g_word', 'Зробив, як домовлялись', FlagKind.g, 1, ['як домовл', 'тримав слово']),
  Flag('flag_g_kind', 'Чемний з усіма, не лише зі мною', FlagKind.g, 1, ['ввічлив', 'чемн', 'з офіціант']),
  Flag('flag_r_phone', 'Сидів у телефоні', FlagKind.r, 1, ['телефон', 'в екран', 'скролив', 'чатився', 'телеграм']),
  Flag('flag_r_self', 'Говорив тільки про себе', FlagKind.r, 1, ['про себе', 'нарцис', 'не дав слова', 'перебив'], 'flag_g_listen'),
  Flag('flag_r_late', 'Запізнився 15+ хв', FlagKind.r, 1, ['запізн', 'затримався', 'чекала'], 'flag_g_ontime'),
  Flag('flag_r_ex', 'Згадував колишню', FlagKind.r, 1, ['колишн', 'минулі стосунк']),
  Flag('flag_r_cheap', 'Рахував кожну копійку', FlagKind.r, 1, ['копійк', 'скинь на карту', 'до гривні']),
  Flag('flag_r_jab', 'Неприємні підколи', FlagKind.r, 1, ['підкол', 'дивний жарт', 'зауваження про зовнішність']),
  Flag('flag_r_drunk', "Був занадто п'яний", FlagKind.r, 1, ['напився', "п'яний", 'в дрова']),
  Flag('flag_r_jealous', 'Ревнував, контролював', FlagKind.r, 1, ['ревн', 'де ти була', 'перевіряв']),
  Flag('flag_r_gone', 'Зник після', FlagKind.r, 1, ['зник', 'ігнор', 'не відписав', 'прочитав і мовчить'], 'flag_g_texts'),
  Flag('flag_r_lie', 'Брехав, щось не збіглось', FlagKind.r, 1, ['брех', 'наврав', 'не збіглось']),
  Flag('flag_r_push', 'Тиснув, квапив', FlagKind.r, 2, ['тисн', 'квап', 'наляг', 'умовляв'], 'flag_g_no'),
  Flag('flag_c_stop', 'Не зупинився на «стоп»', FlagKind.c, 3, ['не зупинився', 'продовжив хоч я']),
  Flag('flag_c_condom', 'Зняв або відмовився від презерватива', FlagKind.c, 3, ['зняв презерватив']),
  Flag('flag_c_photo', 'Знімав без дозволу', FlagKind.c, 3, ['без дозволу']),
];
Flag? flagById(String id) {
  for (final f in flags) {
    if (f.id == id) return f;
  }
  return null;
}

// ---------- Факти (повзунки, у текстах тільки назви) ----------
class Fact {
  final String id, label;
  final List<String> steps;
  final List<String>? hint;
  const Fact(this.id, this.label, this.steps, [this.hint]);
}

const facts = <Fact>[
  Fact('f_stam', 'Витривалість', ['Спринтер', 'Оптимально', 'Марафон', 'Незламний'], ['до ~5 хв', '~5–20 хв', '~20–40 хв', '40+ хв або кілька заходів']),
  Fact('f_budget', 'Бюджет вечора', ['Прогулянка', 'Кава', 'Ресторан', 'Преміум'], ['~0 грн', 'до ~300 грн', '~300–1500 грн', '1500+ грн']),
  Fact('f_init', 'Хто ініціював зустріч', ['Я', 'Порівну', 'Він']),
];

// ---------- Картка людини ----------
const rels = [Opt('date', 'Побачення'), Opt('fling', 'Інтрижка'), Opt('rel', 'Стосунки'), Opt('night', 'Одна ніч'), Opt('ex', 'Колишній')];
String relLabel(String id) => rels.firstWhere((r) => r.id == id, orElse: () => const Opt('', '')).label;
const sizes = ['Скромно', 'Золотий стандарт', 'Вражає', 'Гігант'];
const metOptions = ['Дейтинг', 'Друзі', 'Робота, навчання', 'Бар, вечірка', 'Інстаграм', 'Колишній', 'Інше'];
const wantOptions = ["Без зобов'язань", 'Подивимось', 'Серйозне'];
const pastReasons = [Opt('gone', 'Він зник'), Opt('faded', 'Само згасло'), Opt('ended', 'Я завершила')];
String pastReasonLabel(String? id) => pastReasons.firstWhere((r) => r.id == id, orElse: () => const Opt('', 'У минулих')).label;
const datingOptions = [Opt('men', 'з чоловіками'), Opt('women', 'з жінками'), Opt('all', 'з усіма')];

// ---------- Місця для зустрічей ----------
const places = [
  Opt('bar', 'Бар'), Opt('restaurant', 'Ресторан'), Opt('cafe', 'Кафе'), Opt('park', 'Прогулянка'),
  Opt('cinema', 'Кіно'), Opt('his', 'У нього'), Opt('mine', 'У мене'), Opt('other', 'Інше'),
];
String placeLabel(String? id) => id == null ? '' : places.firstWhere((p) => p.id == id, orElse: () => const Opt('', '')).label;

// ---------- Ліміти безкоштовної версії ----------
const freeEntriesPerMonth = 5;
const freePeople = 3;
