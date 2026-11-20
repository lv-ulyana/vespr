# Знаки зодіаку: суть, кохання, ліжко, тінь. Класичні астрологічні значення (стихія, хрест, планета-управитель),
# трохи романтизовані. Пишемо про знак у множині («Овни»), щоб текст підходив і для тебе, і для нього/неї.
# Порядок — як у lib/logic/astro.dart: Козеріг, Водолій, Риби, Овен, Телець, Близнюки, Рак, Лев, Діва, Терези, Скорпіон, Стрілець.

SIGNS = [
  # Козеріг
  dict(
    core=('Земля і кардинальний хрест, управитель Сатурн. Козероги будують надовго: кар’єру, репутацію, стосунки. Зовні стримані й серйозні, всередині мають сухий гумор і вірність, якою можна перевіряти годинник.',
          'Earth and the cardinal cross, ruled by Saturn. Capricorns build for the long run: career, reputation, relationships. Reserved and serious on the outside, with a dry sense of humour and a loyalty you could set your watch by.'),
    love=('Закохуються повільно, бо спершу перевіряють, чи людина надійна. Почуття показують справами: подбати, домовитись, з’явитись вчасно. Зате якщо вже обрали, то всерйоз і без ігор.',
          'They fall slowly, because first they check whether a person is reliable. They show feelings through actions: taking care, making plans, turning up on time. Once they choose you, it is serious and without games.'),
    bed=('За стриманістю ховається витривалість і дуже земна чуттєвість. Їм потрібна довіра і трохи часу, щоб розслабитись. Коли контроль нарешті відпускає, виявляється, що вони знають, що роблять.',
         'Behind the restraint there is stamina and a very earthy sensuality. They need trust and a little time to relax. When control finally lets go, it turns out they know exactly what they are doing.'),
    shadow=('Робота може з’їсти романтику, а почуття ховаються за «я просто зайнятий». Буває холодність, коли потрібне тепло.',
            'Work can swallow the romance, and feelings hide behind “I’m just busy”. Coldness can show up exactly when warmth is needed.'),
  ),
  # Водолій
  dict(
    core=('Повітря і фіксований хрест, управителі Уран і Сатурн. Водолії живуть ідеями, друзями і власними правилами. Вони дивні у найкращому сенсі: бачать майбутнє раніше за інших і не терплять, коли їх заганяють у рамки.',
          'Air and the fixed cross, ruled by Uranus and Saturn. Aquarians live on ideas, friends and their own rules. They are strange in the best sense: they see the future before others do and cannot stand being boxed in.'),
    love=('Спершу друзі, потім усе інше. Їх приваблює розум, свобода і людина, яка не намагається їх переробити. Близькість для них — це розмова до третьої ночі, а не обов’язкові ритуали.',
          'Friends first, everything else later. They are drawn to a sharp mind, freedom and someone who does not try to remake them. Intimacy for them is a conversation until 3 a.m., not mandatory rituals.'),
    bed=('Експериментатори з холодною головою: цікаво спробувати те, про що інші лише думають. Збудження починається з думки й фантазії. Рутина вбиває їм бажання швидше за будь-що.',
         'Experimenters with a cool head: curious to try what others only think about. Arousal starts with an idea and a fantasy. Routine kills their desire faster than anything.'),
    shadow=('Відстороненість: можуть бути поруч і водночас ніби не тут. Емоції розбирають як теорію, а не відчувають.',
            'Detachment: they can be right there and somehow not present. They analyse emotions like a theory instead of feeling them.'),
  ),
  # Риби
  dict(
    core=('Вода і мутабельний хрест, управителі Нептун і Юпітер. Риби відчувають усе й усіх: настрої, недомовки, музику в кімнаті. Мрійливі, творчі, дуже співчутливі і часто трохи не з цього світу.',
          'Water and the mutable cross, ruled by Neptune and Jupiter. Pisces feel everything and everyone: moods, unspoken things, the music in the room. Dreamy, creative, deeply compassionate and often a little not of this world.'),
    love=('Кохають як у кіно: з повною віддачею, романтикою і бажанням розчинитись одне в одному. Тонко вгадують, чого хоче партнер. Їм важливо, щоб їхню ніжність не сприймали як належне.',
          'They love like in the movies: all in, romantic, wanting to dissolve into each other. They sense what a partner wants with uncanny precision. It matters to them that their tenderness is not taken for granted.'),
    bed=('Найчуттєвіший знак: атмосфера, дотики, емоційне злиття. Можуть підлаштуватись під будь-яку фантазію, але найкраще розкриваються, коли відчувають безпеку і ніжність.',
         'The most sensual sign: atmosphere, touch, emotional merging. They can adapt to any fantasy, but they open up best when they feel safe and cherished.'),
    shadow=('Рожеві окуляри і рятування тих, хто не хоче рятуватись. Схильні тікати від проблем у мрії або мовчання.',
            'Rose-tinted glasses and rescuing people who do not want to be rescued. They tend to escape problems into daydreams or silence.'),
  ),
  # Овен
  dict(
    core=('Вогонь і кардинальний хрест, управитель Марс. Овни — перший знак зодіаку: стартують першими, говорять прямо і живуть на повній швидкості. Сміливі, азартні, швидко спалахують і так само швидко відходять.',
          'Fire and the cardinal cross, ruled by Mars. Aries is the first sign of the zodiac: first off the mark, direct and living at full speed. Brave, competitive, quick to flare up and just as quick to cool down.'),
    love=('Закохуються з першого погляду і одразу діють, без натяків і місяців листування. Їм потрібен азарт, трохи суперництва і партнер, який не боїться їхнього вогню.',
          'They fall at first sight and act right away, no hints and no months of texting. They need excitement, a bit of competition and a partner who is not afraid of their fire.'),
    bed=('Пристрасні, спонтанні, люблять ініціативу і швидкий темп. Для них секс — це гра і трохи змагання. Головне, щоб не було нудно і передбачувано.',
         'Passionate, spontaneous, love taking the lead and a fast pace. For them sex is play with a little competition in it. The main thing is that it is never dull or predictable.'),
    shadow=('Нетерплячість і «я перший»: можуть загорітись і так само швидко згаснути. У суперечках спершу кажуть, потім думають.',
            'Impatience and “me first”: they can catch fire and burn out just as fast. In arguments they speak first and think later.'),
  ),
  # Телець
  dict(
    core=('Земля і фіксований хрест, управителька Венера. Тельці люблять красу, смачну їжу, гарні тканини і стабільність. Спокійні й надійні, поки їх не чіпати, і неймовірно вперті, якщо вже вирішили.',
          'Earth and the fixed cross, ruled by Venus. Taurus loves beauty, good food, fine fabrics and stability. Calm and dependable until pushed, and incredibly stubborn once their mind is made up.'),
    love=('Кохають тілом і турботою: вечеря, обійми, подарунок, який ти колись згадала мимохідь. Їм потрібна вірність і відчуття, що це надовго. Ревниві до свого, зате самі не підводять.',
          'They love through the body and care: dinner, hugs, a gift you mentioned once in passing. They need loyalty and a sense that this is for the long run. Possessive of what is theirs, but they never let you down.'),
    bed=('Знак Венери, тому чуттєвість тут головна: повільно, смачно, з увагою до кожного дотику. Тельці не поспішають і вміють розтягнути задоволення. Важливі запахи, тепло і комфорт.',
         'A Venus sign, so sensuality comes first: slow, delicious, attentive to every touch. Taurus never rushes and knows how to stretch out pleasure. Scents, warmth and comfort matter a lot.'),
    shadow=('Впертість і власництво. Важко пробачають і ще важче змінюють звички, навіть коли ті вже не працюють.',
            'Stubbornness and possessiveness. They forgive with difficulty and change habits even more reluctantly, even when those habits no longer work.'),
  ),
  # Близнюки
  dict(
    core=('Повітря і мутабельний хрест, управитель Меркурій. Близнюки — це цікавість, дотепність і десять відкритих вкладок у голові. Легко знайомляться, легко переключаються і вміють говорити з будь-ким про що завгодно.',
          'Air and the mutable cross, ruled by Mercury. Gemini is curiosity, wit and ten open tabs in their head. They meet people easily, switch easily and can talk to anyone about anything.'),
    love=('Закохуються в розмову: фліртують словами, мемами, повідомленнями о другій ночі. Їм потрібен партнер, з яким цікаво, бо нудьга для них гірша за сварку.',
          'They fall for conversation: flirting with words, memes, messages at 2 a.m. They need a partner who keeps them interested, because boredom is worse to them than a fight.'),
    bed=('Грайливі, балакучі, люблять різноманітність і нові ідеї. Найсексуальніший орган у них — мозок, тож підійдуть і брудні розмови, і рольові ігри. Однаковий сценарій двічі — вже рутина.',
         'Playful, talkative, they love variety and new ideas. Their sexiest organ is the brain, so dirty talk and role-play both work. The same script twice already feels like routine.'),
    shadow=('Непостійність: сьогодні палко, завтра вже захопились іншим. Можуть уникати глибоких розмов про почуття за жартами.',
            'Inconsistency: passionate today, distracted by something else tomorrow. They can dodge deep talks about feelings with jokes.'),
  ),
  # Рак
  dict(
    core=('Вода і кардинальний хрест, управитель Місяць. Раки — серце зодіаку: дім, сім’я, пам’ять і турбота. Під твердим панцирем дуже ніжна душа, яка все відчуває і нічого не забуває.',
          'Water and the cardinal cross, ruled by the Moon. Cancer is the heart of the zodiac: home, family, memory and care. Under a hard shell there is a very tender soul that feels everything and forgets nothing.'),
    love=('Кохають, щоб створити свій маленький світ на двох. Дбають, годують, пам’ятають дати і дрібниці. Їм потрібно відчувати, що їх обирають щодня, а не тільки на свята.',
          'They love in order to build a small world for two. They care, feed, remember dates and details. They need to feel chosen every day, not just on holidays.'),
    bed=('Емоційні й дуже ніжні: секс для них — це близькість, а не техніка. Розкриваються поступово, зате потім стають щедрими і уважними. Найкраще працює довіра, обійми після і відчуття дому.',
         'Emotional and very tender: for them sex is closeness, not technique. They open up gradually, but then become generous and attentive. Trust, cuddles afterwards and a feeling of home work best.'),
    shadow=('Образливість і настрої, як припливи. Можуть ховатись у панцир і чекати, що ти сама здогадаєшся, що не так.',
            'Touchiness and moods like tides. They can hide in their shell and wait for you to guess what is wrong.'),
  ),
  # Лев
  dict(
    core=('Вогонь і фіксований хрест, управитель Сонце. Леви — щедрі, яскраві й теплі, їх неможливо не помітити. Вони люблять сцену, компліменти і людей, яким можна дарувати своє світло.',
          'Fire and the fixed cross, ruled by the Sun. Leos are generous, bright and warm, impossible to miss. They love the spotlight, compliments and people they can share their light with.'),
    love=('Кохають велично: жести, сюрпризи, публічна гордість за партнера. Віддані й захисні, як справжні королі. Натомість чекають захоплення і того, що їх будуть цінувати вголос.',
          'They love grandly: gestures, surprises, public pride in their partner. Devoted and protective, like real royalty. In return they expect admiration and to be appreciated out loud.'),
    bed=('Пристрасні, впевнені і трохи театральні: люблять, щоб було гарно і щоб ними захоплювались. Щедрі на увагу, теплі й грайливі. Компліменти працюють на них краще за будь-яку прелюдію.',
         'Passionate, confident and a little theatrical: they like it beautiful and they like being admired. Generous with attention, warm and playful. Compliments work on them better than any foreplay.'),
    shadow=('Его і потреба бути в центрі. Ображаються, коли їх не помітили, і важко визнають помилки.',
            'Ego and the need to be the centre of attention. They sulk when they go unnoticed and struggle to admit mistakes.'),
  ),
  # Діва
  dict(
    core=('Земля і мутабельний хрест, управитель Меркурій. Діви помічають деталі, які інші пропускають, і роблять світ трохи кращим, ніж він був. Розумні, практичні, турботливі через справи і дуже вимогливі, найперше до себе.',
          'Earth and the mutable cross, ruled by Mercury. Virgos notice details others miss and leave the world a bit better than they found it. Smart, practical, caring through actions and very demanding, first of all of themselves.'),
    love=('Кохання в них тихе і уважне: принесуть ліки, полагодять кран, запам’ятають, яку каву ти п’єш. Відкриваються не одразу, бо спершу хочуть зрозуміти людину. Цінують чесність і порядок у стосунках.',
          'Their love is quiet and attentive: bringing medicine, fixing the tap, remembering how you take your coffee. They do not open up at once, because first they want to understand you. They value honesty and order in a relationship.'),
    bed=('За скромністю — уважність до деталей і бажання зробити все ідеально. Діви добре вчаться і запам’ятовують, що тобі подобається. Розслабитись їм допомагає чистота, довіра і відсутність поспіху.',
         'Behind the modesty there is attention to detail and a wish to get everything just right. Virgos learn fast and remember what you like. Cleanliness, trust and no rushing help them relax.'),
    shadow=('Критика й перфекціонізм: можуть розбирати тебе і себе під мікроскопом. Тривожність маскується під «я просто хочу як краще».',
            'Criticism and perfectionism: they can examine you and themselves under a microscope. Anxiety disguises itself as “I just want it to be better”.'),
  ),
  # Терези
  dict(
    core=('Повітря і кардинальний хрест, управителька Венера. Терези шукають гармонію, красу і справедливість. Чарівні, дипломатичні, зі смаком, вміють помирити будь-кого, крім себе зі своїми сумнівами.',
          'Air and the cardinal cross, ruled by Venus. Libras seek harmony, beauty and fairness. Charming, diplomatic, with great taste, they can reconcile anyone except themselves with their own doubts.'),
    love=('Знак партнерства: їм добре, коли вони вдвох. Романтичні, уважні до естетики побачень, люблять красиві жести і рівність. Найбільше цінують, коли їх чують і з ними рахуються.',
          'The sign of partnership: they thrive as a couple. Romantic, attentive to the aesthetics of a date, they love beautiful gestures and equality. What they value most is being heard and taken into account.'),
    bed=('Венера робить їх чуттєвими естетами: світло, музика, гарна білизна. Дуже зважають на задоволення партнера і чекають того ж у відповідь. Грубість і поспіх їх швидко вимикають.',
         'Venus makes them sensual aesthetes: lighting, music, beautiful lingerie. They care a lot about a partner’s pleasure and expect the same back. Rudeness and rushing switch them off quickly.'),
    shadow=('Нерішучість і бажання всім подобатись. Можуть ковтати образи заради миру, а потім раптово піти.',
            'Indecision and the wish to please everyone. They may swallow hurt for the sake of peace and then suddenly leave.'),
  ),
  # Скорпіон
  dict(
    core=('Вода і фіксований хрест, управителі Плутон і Марс. Скорпіони — інтенсивність у чистому вигляді: глибина, таємниця, сила волі. Бачать людей наскрізь і ніколи не роблять нічого наполовину.',
          'Water and the fixed cross, ruled by Pluto and Mars. Scorpio is intensity in its purest form: depth, mystery, willpower. They see right through people and never do anything halfway.'),
    love=('Кохають усім єством і хочуть того ж у відповідь. Їм потрібна повна довіра, чесність до дрібниць і емоційна глибина. Зрада для них — точка, з якої не повертаються.',
          'They love with their whole being and want the same in return. They need complete trust, honesty down to the details and emotional depth. Betrayal is a point of no return for them.'),
    bed=('Найпристрасніший знак зодіаку за репутацією: магнетизм, інтенсивність, повна віддача. Для них секс — це злиття і трохи влади. Вміють тримати напругу і доводити до краю.',
         'The most passionate sign of the zodiac by reputation: magnetism, intensity, total surrender. For them sex is merging, with a hint of power play. They know how to hold the tension and take you to the edge.'),
    shadow=('Ревнощі, контроль і мовчазні образи. Можуть перевіряти, випробовувати і довго пам’ятати.',
            'Jealousy, control and silent grudges. They can test you, push your limits and remember for a long time.'),
  ),
  # Стрілець
  dict(
    core=('Вогонь і мутабельний хрест, управитель Юпітер. Стрільці — мандрівники і філософи: нові країни, ідеї, люди. Оптимісти з гучним сміхом і чесністю, яка іноді б’є влучніше, ніж хотілося б.',
          'Fire and the mutable cross, ruled by Jupiter. Sagittarians are travellers and philosophers: new countries, ideas, people. Optimists with a loud laugh and an honesty that sometimes hits harder than intended.'),
    love=('Закохуються в пригоду: спонтанні поїздки, сміх, спільні відкриття. Їм потрібна свобода і партнер, який стане співучасником, а не наглядачем. Ревнощі й контроль швидко женуть їх геть.',
          'They fall in love with adventure: spontaneous trips, laughter, discoveries together. They need freedom and a partner who is an accomplice, not a supervisor. Jealousy and control drive them away fast.'),
    bed=('Веселі, енергійні, відкриті до нового: секс для них як подорож, де цікаво, що за поворотом. Люблять сміятись у ліжку і пробувати незвичні місця. Головне — легкість і без драми.',
         'Fun, energetic, open to new things: sex for them is a journey where it is exciting to see what is round the corner. They love laughing in bed and trying unusual places. The key is lightness and no drama.'),
    shadow=('Страх зобов’язань і обіцянки, які легко даються й легко забуваються. Можуть зникнути, коли стає занадто серйозно.',
            'Fear of commitment and promises that are easily made and easily forgotten. They can vanish when things get too serious.'),
  ),
]
