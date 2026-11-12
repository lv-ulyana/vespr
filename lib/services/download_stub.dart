// На телефоні завантаження «як у браузері» не потрібне: там є системне «Поділитися».
void downloadBytes(List<int> bytes, String name, String mime) => throw UnsupportedError('Тільки у веб-версії');
