_q = [
"You came into my life at a time when I'd stopped believing in coincidences",
"There was always something between us bigger than words. Maybe that's why we were so often quiet",
"I'd recognize you even in a life where we never met",
"Some looks make every other look feel like just eyes",
"I loved how the world got quieter when you were near",
"We never promised each other forever. We just sometimes looked at each other like it had already begun",
"I remember people not by their words, but by how easy it was to breathe next to them",
"I didn't want to be your greatest adventure. I wanted to be your calmest evening",
"You touched my hand like you were afraid to wake something beautiful",
"Your voice had something of a home I'd never been back to before",
"I didn't need the stars. The light from your kitchen at 2 a.m. was enough",
"Maybe love is wanting to tell someone even how the rain smelled today",
"We stayed in each other longer than we stayed together",
"You left, and for a while I still lived as if I had someone to tell about my day",
"Some people don't come to stay. They come to change what certain songs mean forever",
"We were almost love. And that “almost” somehow hurt the most",
"I'm not waiting for you anymore. Some evenings just look too much like ours",
"The stories that live longest are the ones never allowed to end",
"Maybe in some other city we're still sitting across from each other, not afraid to tell the truth",
"We didn't have a future together, but we had so much sky in common",
"You were like August: I knew it would end, and I still fell for its evenings",
"Some people leave even familiar streets keeping secrets",
"I think some souls meet before the people have time to say their names",
"How strange: we can be strangers and still know what the silence between us sounds like",
"You were my favorite coincidence",
"Some feelings are more beautiful before they have a name",
"I wanted to stay wherever you were laughing",
"Every heart has its own geography. Mine somehow remembers your coordinates",
"We met for a short while, but inside me it lasted forever",
"And if someone ever asks me about tenderness, I'll think of a moment, not a word",
"Out of millions of accidents, you became my favorite",
"I don't need a perfect world if mine has you in it",
"Sometimes home isn't a place, it's someone's arms",
"I love not only you, but who I am next to you",
"You're my favorite “what if everything turns out fine?”",
"If calm had a voice, it would sound like yours",
"The most beautiful moments are the ones where we forget about time",
"I love that even silence with you means something",
"Of all the places on earth, the one I most want to be is next to you",
"You came into my life so quietly and changed so much of it",
"Love is being seen as you really are and still being chosen",
"The deepest tenderness is knowing someone's weaknesses and never using them against them",
"You can fall for a smile, but you stay for a soul",
"Real closeness begins where you no longer have to pretend",
"I wasn't looking for someone to make me happy. I was looking for someone I'd want to share happiness with",
"Sometimes one person doesn't change your life, they change how you look at it",
"Love isn't a promise to never fight. It's wanting to find each other even after the fights",
"The most precious thing is when no one tries to change you, but helps you bloom",
"Being loved isn't always hearing beautiful words. Sometimes it's just knowing someone is waiting for you",
"I don't want a fairy tale without hard parts, I want a person who makes them less scary",
"There are people we let go of with our hands but hold on to with our hearts for a long time",
"Sometimes you miss not the person, but who you were next to them",
"We never became forever, but for a moment we were a whole world",
"Some hugs end, but the feeling stays for years",
"The saddest thing is when two people still love each other but no longer know how to be together",
"You're my favorite accident",
"In your eyes I find quiet",
"My heart recognized you before my mind did",
"Of all the “maybes,” I choose our “yes”",
"If I could stop time, I'd choose the moment you're holding me",
]
T = {'Думка дня': 'Thought of the day', 'Факт дня': 'Fact of the day'}
import re as _re
_uk = _re.findall(r"'(«[^']*»)'", open(ROOT + '/lib/logic/facts.dart').read())
assert len(_uk) == len(_q) == 60
for _a, _b in zip(_uk, _q): T[_a] = '“' + _b + '”'
# лічильник «ще N записів»
for n, w in (('запис', 'entry'), ('записи', 'entries'), ('записів', 'entries')):
    T['Ще {0} %s, і скажемо щось точне.' % w if False else 'Ще {0} %s, і скажемо щось точне.' % n] = '{0} more %s and we can say something real.' % w
    T['Ще {0} %s до перших висновків.' % n] = '{0} more %s until the first insights.' % w
T['Ще 1 запис, і скажемо щось точне.'] = 'One more entry and we can say something real.'
T['Ще 1 запис до перших висновків.'] = 'One more entry until the first insights.'
# демо
T.update({'Архітектор': 'The Architect', 'Креслить на серветках': 'Sketches on napkins', 'Марк': 'Mark', 'Д.': 'D.', 'Ляна': 'Lana',
 'Довго гуляли, потім у нього': 'Long walk, then his place', 'Весь вечір у телефоні': 'On his phone all night',
 'Запізнився на 40 хвилин': '40 minutes late', 'Найкращий вечір місяця': 'Best night of the month'})
T.update({'Сьогодні': 'Today', 'Завтра': 'Tomorrow'})
T['Моя мапа у Vespr'] = 'My map on Vespr'
T.update({
 'Ти {0} + він {1} · {2}': 'You {0} + him {1} · {2}',
 'Ти {0} + вона {1} · {2}': 'You {0} + her {1} · {2}',
 'Плюс {0} до вечора дає': 'Adds {0} to the night:',
 'Мінус {0} до вечора дає': 'Takes {0} off the night:',
 'він': 'him', 'вона': 'her',
 '— він вийшов з чату —': '— he left the chat —',
 '{0}\nяк людина': '{0}\nas a person',
})
