_m = ['January','February','March','April','May','June','July','August','September','October','November','December']
_ms = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
_uk_nom = ['січень','лютий','березень','квітень','травень','червень','липень','серпень','вересень','жовтень','листопад','грудень']
_uk_gen = ['січня','лютого','березня','квітня','травня','червня','липня','серпня','вересня','жовтня','листопада','грудня']
_uk_loc = ['січні','лютому','березні','квітні','травні','червні','липні','серпні','вересні','жовтні','листопаді','грудні']
_uk_sh = ['січ','лют','бер','квіт','трав','черв','лип','серп','вер','жовт','лист','груд']
W = {}
for i in range(12):
    W[_uk_nom[i]] = _m[i]; W[_uk_nom[i].capitalize()] = _m[i]
    W[_uk_gen[i]] = _m[i]; W[_uk_loc[i]] = _m[i]; W[_uk_sh[i]] = _ms[i]
_wd = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday']
for uk, en in zip(['понеділок','вівторок','середа','четвер','пʼятниця','субота','неділя'], _wd): W[uk] = en; W[uk.capitalize()] = en
for uk, en in zip(['середу','пʼятницю','суботу','неділю'], ['Wednesday','Friday','Saturday','Sunday']): W[uk] = en
for uk, en in zip(['пн','вт','ср','чт','пт','сб','нд'], ['Mon','Tue','Wed','Thu','Fri','Sat','Sun']): W[uk] = en; W[uk.capitalize()] = en
W.update({
 'раз': 'time', 'рази': 'times', 'разів': 'times',
 'запис': 'record', 'записи': 'records', 'записів': 'records', 'записом': 'record', 'записами': 'records',
 'зустріч': 'date', 'зустрічі': 'dates', 'зустрічей': 'dates',
 'людина': 'person', 'людини': 'people', 'людей': 'people',
 'побачення': 'dates', 'день': 'day', 'дні': 'days', 'днів': 'days', 'тиждень': 'week', 'тижні': 'weeks', 'тижнів': 'weeks',
 'місяць': 'month', 'місяці': 'months', 'місяців': 'months', 'рік': 'year', 'роки': 'years', 'років': 'years',
 'хв': 'min', 'хвилин': 'minutes', 'хвилини': 'minutes', 'хвилина': 'minute', 'год': 'h',
 'сьогодні': 'today', 'Сьогодні': 'Today', 'завтра': 'tomorrow', 'Завтра': 'Tomorrow', 'вчора': 'yesterday', 'Вчора': 'Yesterday',
 'з': 'of', 'і': 'and', 'та': 'and', 'о': 'at', 'в': 'on', 'у': 'on',
 'чоловік': 'man', 'чоловіки': 'men', 'чоловіків': 'men', 'хлопець': 'guy', 'хлопці': 'guys', 'хлопців': 'guys',
 'прапорець': 'flag', 'прапорці': 'flags', 'прапорців': 'flags',
 'нагорода': 'award', 'нагороди': 'awards', 'нагород': 'awards',
 'закономірність': 'pattern', 'закономірності': 'patterns', 'закономірностей': 'patterns',
 'оргазм': 'orgasm', 'оргазми': 'orgasms', 'оргазмів': 'orgasms',
 'секс': 'sex', 'вечір': 'night', 'вечори': 'nights', 'вечорів': 'nights',
 'бал': 'pt', 'бали': 'pts', 'балів': 'pts', 'бала': 'pts',
 'питання': 'questions', 'відповідь': 'answer', 'відповіді': 'answers', 'відповідей': 'answers',
 'голосове': 'voice note', 'голосові': 'voice notes', 'голосових': 'voice notes',
 'ніч': 'night', 'ночі': 'nights', 'ночей': 'nights',
 'годину': 'hour', 'години': 'hours', 'годин': 'hours',
 'клоун': 'clown', 'клоуни': 'clowns', 'клоунів': 'clowns',
 'граблі': 'rakes',
})
T = {
 'Точно': 'Certain', 'Закономірність': 'Pattern', 'Схоже': 'Likely', 'Прапорці': 'Flags',
 'Ще {0} {1}, і скажемо щось точне.': 'Just {0} more {1} and we’ll tell you something real.',
 'Ще {0} {1} до перших висновків.': '{0} more {1} until the first insights.',
 'Тільки у веб-версії': 'Web version only',
 'Vespr: зустріч': 'Vespr: date', 'Копія Vespr': 'Vespr backup',
 'Це не файл копії Vespr': 'This isn’t a Vespr backup file',
 'Це не файл копії Vespr або він з іншої версії': 'This isn’t a Vespr backup, or it’s from another version',
 'Неправильний пароль': 'Wrong password',
 'Немає доступу до календаря. Дозволь його в налаштуваннях телефону: Vespr → Дозволи → Календар.': 'No access to your calendar. Allow it in your phone settings: Vespr → Permissions → Calendar.',
 'Підтверди, що це ти, щоб задати новий PIN': 'Confirm it’s you to set a new PIN',
 'Нагадування за годину до зустрічі': 'A reminder one hour before a date',
 'Через годину зустріч, о {0}.': 'Date in an hour, at {0}.',
 'Зустрічі': 'Dates',
 'Крок {0} з {1}': 'Step {0} of {1}', 'Оцінка {0}': 'Rating {0}',
 'Фото завелике, вибери інше': 'That photo’s too big, pick another one',
 'Не вдалось відкрити фото': 'Couldn’t open the photo',
 'Головна': 'Home',
 'Усі записи\n': 'All records\n', 'одним списком': 'in one list',
 'Тапни на стовпець, щоб відсортувати. Тапни на рядок, щоб відкрити запис.': 'Tap a column to sort. Tap a row to open the record.',
 'Записів поки нема. Вела раніше в таблиці чи календарі? Перенеси їх сюди ›': 'No records yet. Kept track in a spreadsheet or calendar before? Bring them over ›',
 '{0} {1} · середня {2}': '{0} {1} · avg {2}',
 'Сортувати: {0}': 'Sort: {0}',
 'Твій ідеальний вечір: {0}, {1} і {2}.': 'Your perfect night: {0}, {1} and {2}.',
 '«{0}»: плюс {1} до вечора. Схоже, це твоє.': '“{0}”: plus {1} to the night. Looks like your thing.',
 '«{0}» піднімає вечір на {1}. Цифри не брешуть.': '“{0}” lifts the night by {1}. Numbers don’t lie.',
 '«{0}»: мінус {1} до вечора, і вже {2}.': '“{0}”: minus {1} to the night, {2} already.',
 '«{0}» опускає вечір на {1}. Варто помітити.': '“{0}” drags the night down by {1}. Worth noticing.',
 'Найкраще тобі {0} {1}: в середньому {2} проти {3}.': '{1}s are your best: {2} on average vs {3}.',
 '{0}: останні три зустрічі кращі за попередні три. Росте.': '{0}: the last three dates beat the three before. Growing.',
 '{0}: останні три зустрічі слабші за попередні три. Це вже не випадковість.': '{0}: the last three dates were weaker than the three before. Not a coincidence anymore.',
 '{0}: у ліжку {1}, а як людина {2}. Тілу добре, голові менше.': '{0}: {1} in bed, {2} as a person. Body says yes, head says hmm.',
 '{0}: як людина {1}, а в ліжку поки {2}.': '{0}: {1} as a person, only {2} in bed so far.',
 '{0}, «{1}»: уже {2}. Це характер, а не випадок.': '{0}, “{1}”: {2} already. That’s character, not chance.',
 '{0}, «{1}»: уже {2}. Ти це бачиш, і мапа теж.': '{0}, “{1}”: {2} already. You see it, and so does the map.',
}
