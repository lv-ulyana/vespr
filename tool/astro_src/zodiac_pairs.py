# Сумісність знаків: аспект (відстань між знаками на колі, 0–6) і пара стихій.
# Легкість аспекту мусить збігатися з zodiacEase (стихії): 0, 2, 4, 6 — «Легко»; 1, 3, 5 — «Складніше».
# *…* — акцент кольором.

ASPECTS = [
  # 0 — той самий знак (з'єднання)
  dict(
    name=('Один знак', 'Same sign'), easy=True,
    rel=('Ви з одного знака, тож розумієте одне одного з півслова: *ті самі цінності, ті самі реакції*. Поруч легко, бо не треба нічого пояснювати. Головне завдання — не перетворитись на дзеркала, які лише повторюють одне одного.',
         'You share a sign, so you understand each other in half a word: *the same values, the same reactions*. It is easy together because nothing needs explaining. The main task is not to turn into mirrors that only repeat each other.'),
    sex=('Ви відчуваєте ритм одне одного без підказок, тому *хімія вмикається швидко*. Але й бажання у вас однакові, тож новизну доведеться приносити свідомо.',
         'You feel each other’s rhythm without prompts, so *the chemistry switches on fast*. But your desires are the same too, so novelty has to be brought in on purpose.'),
    risk=('Ті самі слабкості помножені на два. Якщо обоє вперті або обоє уникають розмов, ніхто не поступиться першим.',
          'The same weaknesses times two. If you are both stubborn or both avoid hard talks, nobody gives in first.'),
  ),
  # 1 — сусідні знаки (напівсекстиль)
  dict(
    name=('Сусідні знаки', 'Neighbouring signs'), easy=False,
    rel=('Ви сусіди на зодіакальному колі: стихії різні, і *кожен бачить у другому те, чого бракує самому*. Це стосунки-навчання: дратує, але й змушує рости. Потрібно більше слів, ніж здається.',
         'You are neighbours on the zodiac wheel: different elements, and *each sees in the other what they lack*. It is a learning relationship: irritating at times, but it makes you grow. It needs more words than it seems.'),
    sex=('Різний темп і різні мови бажання. *Цікаво саме через різницю*, якщо обоє готові питати й підказувати.',
         'Different pace and different languages of desire. *It is exciting precisely because of the difference*, if you are both ready to ask and guide.'),
    risk=('Дрібні непорозуміння накопичуються, бо здається, що все очевидно. Мовчання тут шкодить більше, ніж сварка.',
          'Small misunderstandings pile up because everything seems obvious. Silence hurts more here than a fight.'),
  ),
  # 2 — секстиль
  dict(
    name=('Секстиль', 'Sextile'), easy=True,
    rel=('Секстиль — аспект дружби і можливостей. Ваші стихії доповнюють одна одну, тож *разом легко щось починати*: плани, поїздки, спільні справи. Найкраще працює, коли ви обоє вкладаєтесь.',
         'A sextile is the aspect of friendship and opportunity. Your elements complement each other, so *it is easy to start things together*: plans, trips, shared projects. It works best when you both put in effort.'),
    sex=('Легко, весело і без напруги. *Ви підхоплюєте ідеї одне одного*, і з часом стає тільки краще.',
         'Easy, fun and without tension. *You pick up each other’s ideas*, and it only gets better with time.'),
    risk=('Можливості, якими не скористались. Якщо обоє чекають, що ініціативу візьме інший, все так і лишиться приємним, але поверховим.',
          'Opportunities left unused. If you both wait for the other to take the lead, it stays pleasant but shallow.'),
  ),
  # 3 — квадрат
  dict(
    name=('Квадрат', 'Square'), easy=False,
    rel=('Квадрат — класичний аспект напруги: ви з одного хреста, але різних стихій. *Іскрить і в хорошому, і в поганому сенсі*. Такі пари або вчаться домовлятися і стають дуже сильними, або втомлюються від постійного тертя.',
         'A square is the classic aspect of tension: same cross, different elements. *Sparks fly in both the good and the bad sense*. Such couples either learn to negotiate and become very strong, or wear out from constant friction.'),
    sex=('Багато пристрасті саме через опір. *Примирення після сварки* в таких пар буває найкращим, але не варто будувати на цьому все.',
         'Lots of passion precisely because of the resistance. *Make-up sex after a fight* can be the best for these couples, but you should not build everything on it.'),
    risk=('Боротьба за владу і бажання переробити одне одного. Коли обоє тиснуть, ніхто не чує.',
          'Power struggles and wanting to remake each other. When you both push, nobody listens.'),
  ),
  # 4 — тригон
  dict(
    name=('Тригон', 'Trine'), easy=True,
    rel=('Тригон — найгармонійніший аспект: одна стихія, різні знаки. *Вам просто добре разом*, без зусиль і пояснень. Підтримуєте одне одного природно, як дихаєте.',
         'A trine is the most harmonious aspect: same element, different signs. *You simply feel good together*, without effort or explanations. You support each other as naturally as breathing.'),
    sex=('Природна сумісність: *тіла домовляються самі*. Темп, бажання й фантазії збігаються частіше, ніж зазвичай.',
         'Natural compatibility: *the bodies work it out by themselves*. Pace, desire and fantasies match more often than usual.'),
    risk=('Занадто комфортно. Без викликів стосунки можуть заснути, тож іноді треба самим розхитувати човен.',
          'Too comfortable. Without challenges the relationship can fall asleep, so sometimes you need to rock the boat yourselves.'),
  ),
  # 5 — квінконс
  dict(
    name=('Квінконс', 'Quincunx'), easy=False,
    rel=('Квінконс — найдивніший аспект: у вас немає нічого спільного ні в стихії, ні в хресті. *Вас тягне одне до одного, але важко пояснити чому*. Такі пари постійно підлаштовуються, і це або загартовує, або виснажує.',
         'A quincunx is the strangest aspect: you share neither element nor cross. *You are drawn to each other but it is hard to say why*. Such couples keep adjusting, which either toughens them or wears them out.'),
    sex=('Непередбачувано: то дуже добре, то зовсім не в такт. *Треба вчитися мові одне одного* з нуля і не соромитись питати.',
         'Unpredictable: sometimes amazing, sometimes completely out of sync. *You have to learn each other’s language* from scratch and not be shy to ask.'),
    risk=('Відчуття, що постійно щось не так, хоча ніхто не винен. Легко почати змінювати себе до невпізнання.',
          'A feeling that something is always slightly off, even though nobody is to blame. It is easy to start changing yourself beyond recognition.'),
  ),
  # 6 — опозиція
  dict(
    name=('Опозиція', 'Opposition'), easy=True,
    rel=('Опозиція — протилежні знаки, які притягуються як магніти. Ваші стихії сумісні, але *кожен має те, чого бракує другому*. Разом ви ніби одна ціла картина, якщо не тягнете ковдру кожен на себе.',
         'An opposition is opposite signs that attract like magnets. Your elements are compatible, but *each has what the other lacks*. Together you form one whole picture, as long as neither pulls the blanket their way.'),
    sex=('Сильне притягання протилежностей. *Напруга між вами — це паливо*, і її вистачає надовго.',
         'A strong pull of opposites. *The tension between you is fuel*, and there is plenty of it.'),
    risk=('Гойдалки: зближення, відштовхування і знову зближення. Важливо бачити в різниці доповнення, а не загрозу.',
          'A seesaw: closeness, distance and closeness again. It matters to see the difference as a complement, not a threat.'),
  ),
]

# Пара стихій → порада (ключ складається в коді з відсортованих назв)
ELEMENTS = {
  ('Вогонь', 'Вогонь'): ('Вогонь і вогонь: два багаття поруч. Багато іскор, сміху, пригод і суперечок. Головне — не змагатися, хто яскравіший, і вчасно давати одне одному остигнути.',
                          'Fire and fire: two bonfires side by side. Plenty of sparks, laughter, adventures and arguments. The key is not to compete over who shines brighter and to let each other cool down in time.'),
  ('Вогонь', 'Повітря'): ('Повітря розпалює вогонь: легко, весело, швидко. Ідеї одного стають пригодами другого. Варто домовитись, хто тримає плани, бо інакше все лишиться в розмовах.',
                           'Air feeds fire: easy, fun, fast. One person’s ideas become the other’s adventures. Agree on who keeps the plans, or everything stays in conversation.'),
  ('Вогонь', 'Земля'): ('Вогонь поспішає, земля гальмує. Один хоче тут і зараз, другий — надійно і назавжди. Знайдіть спільний темп, і буде і пристрасть, і опора.',
                         'Fire rushes, earth slows down. One wants it here and now, the other safe and forever. Find a shared pace and you get both passion and stability.'),
  ('Вогонь', 'Вода'): ('Вогонь і вода: пристрасть і пара. Емоції сильні з обох боків, але виражаються по-різному: один кричить, другий ображається мовчки. Говоріть про почуття вголос, поки вони не закипіли.',
                        'Fire and water: passion and steam. Emotions run strong on both sides but come out differently: one shouts, the other sulks in silence. Talk about feelings out loud before they boil over.'),
  ('Повітря', 'Повітря'): ('Два повітряні знаки: багато розмов, свободи й легкості, мало побуту. Вам ніколи не нудно разом. Добре, якщо хтось береться за плани, бо інакше все розлітається.',
                           'Two air signs: lots of talk, freedom and lightness, little routine. You are never bored together. It helps if someone takes charge of plans, otherwise everything blows away.'),
  ('Земля', 'Повітря'): ('Земля хоче опори, повітря свободи. Один планує, другий мріє. Домовтесь про темп і плани, щоб не тягнути в різні боки, і ви навчитеся одне в одного багато чого.',
                          'Earth wants stability, air wants freedom. One plans, the other dreams. Agree on pace and plans so you do not pull in different directions, and you will learn a lot from each other.'),
  ('Вода', 'Повітря'): ('Повітря думає, вода відчуває. Один хоче обговорити, другий — щоб його просто зрозуміли. Перекладайте одне одному почуття словами, а слова — у турботу.',
                         'Air thinks, water feels. One wants to talk it through, the other wants to be understood. Translate feelings into words for each other, and words into care.'),
  ('Земля', 'Земля'): ('Дві землі: надійно, спокійно, із спільними цілями і затишним побутом. Ви будуєте разом щось справжнє. Не забувайте додавати новизни, бо стабільність легко стає рутиною.',
                        'Two earth signs: reliable, calm, with shared goals and a cosy home life. You build something real together. Do not forget to add novelty, because stability easily turns into routine.'),
  ('Вода', 'Земля'): ('Вода живить землю: тепло, турбота, довіра. Земля дає воді береги, вода дає землі ніжність. Одна з найлегших пар зодіаку.',
                       'Water nourishes earth: warmth, care, trust. Earth gives water its banks, water gives earth tenderness. One of the easiest pairings in the zodiac.'),
  ('Вода', 'Вода'): ('Дві води: глибоко, емоційно, майже телепатично. Ви відчуваєте одне одного без слів. Стежте, щоб не потонути в настроях одне одного, і хоч іноді виходьте на берег.',
                      'Two water signs: deep, emotional, almost telepathic. You sense each other without words. Make sure you do not drown in each other’s moods, and come up for air now and then.'),
}
