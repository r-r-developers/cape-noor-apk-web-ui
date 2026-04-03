-- =============================================================================
-- Seed: Duas categories and duas (public domain Islamic sources)
-- Sources: Hisnul Muslim (Fortress of the Muslim) by Sa'id Al-Qahtani
-- =============================================================================

-- Clear existing (safe for fresh install)
DELETE FROM duas;
DELETE FROM duas_categories;
ALTER TABLE duas_categories AUTO_INCREMENT = 1;
ALTER TABLE duas AUTO_INCREMENT = 1;

-- ── Categories ────────────────────────────────────────────────────────────────
INSERT INTO duas_categories (name_ar, name_en, icon) VALUES
('الصباح والمساء',        'Morning & Evening',        'wb_sunny'),
('الصلاة',               'Prayer',                   'mosque'),
('النوم واليقظة',         'Sleep & Waking',           'bedtime'),
('الطعام والشراب',        'Food & Drink',             'restaurant'),
('دخول المنزل والخروج',   'Entering & Leaving Home',  'home'),
('المسجد',               'Masjid',                   'place_of_worship'),
('السفر',                'Travel',                   'flight'),
('القرآن الكريم',         'Quran',                   'menu_book'),
('الاستغفار والتوبة',     'Seeking Forgiveness',      'refresh'),
('الشكر والثناء',         'Gratitude & Praise',       'favorite'),
('المرض والشفاء',         'Illness & Healing',        'healing'),
('الرزق والخير',          'Sustenance & Goodness',    'monetization_on'),
('الهداية والعلم',        'Guidance & Knowledge',     'school'),
('الحماية',              'Protection',               'shield'),
('الأذكار المختلفة',      'Miscellaneous Dhikr',      'auto_awesome');

-- ── Duas: Morning & Evening (1) ───────────────────────────────────────────────
INSERT INTO duas (category_id, title_en, arabic, transliteration, translation, reference) VALUES
(1, 'Morning Remembrance — Sovereignty of Allah',
 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذَا الْيَوْمِ وَخَيْرَ مَا بَعْدَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذَا الْيَوْمِ وَشَرِّ مَا بَعْدَهُ.',
 'Asbahnaa wa asbahal mulku lillah, wal hamdu lillah, laa ilaaha illallahu wahdahu laa sharika lah, lahul mulku wa lahul hamdu wa huwa ala kulli shay''in qadeer. Rabbi as''aluka khayra maa fi haadhaal yawm wa khayra maa ba''dah, wa a''udhu bika min sharri maa fi haadhaal yawm wa sharri maa ba''dah.',
 'We have reached the morning and at this very time the sovereignty belongs to Allah. All praise is for Allah. None has the right to be worshipped except Allah, alone, without partner, to Him belongs all sovereignty and praise, and He is over all things omnipotent. My Lord, I ask You for the good of this day and the good of what follows it, and I take refuge in You from the evil of this day and the evil of what follows it.',
 'Muslim 4:2088'),

(1, 'Evening Remembrance — Sovereignty of Allah',
 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.',
 'Amsaynaa wa amsal mulku lillah, wal hamdu lillah, laa ilaaha illallahu wahdahu laa sharika lah, lahul mulku wa lahul hamdu wa huwa ala kulli shay''in qadeer.',
 'We have reached the evening and at this very time the sovereignty belongs to Allah. All praise is for Allah. None has the right to be worshipped except Allah, alone, without partner, to Him belongs all sovereignty and praise, and He is over all things omnipotent.',
 'Muslim 4:2088'),

(1, 'Sayyid al-Istighfar (Master Supplication of Forgiveness)',
 'اللَّهُمَّ أَنْتَ رَبِّي، لاَ إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي، فَإِنَّهُ لاَ يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ.',
 'Allahumma anta rabbi, laa ilaaha illa anta, khalaqtani wa ana abduk, wa ana ala ahdika wa wa''dika mastata''t, a''udhu bika min sharri maa sana''t, aboo''u laka bini''matika alaiya, wa aboo''u bidhannbi faghfirli, fa''innahu laa yaghfirudh dhunuba illa ant.',
 'O Allah, You are my Lord, none has the right to be worshipped except You, You created me and I am Your servant, and I abide to Your covenant and promise as best I can, I take refuge in You from the evil of which I have committed, I acknowledge Your favour upon me and I acknowledge my sin, so forgive me, for verily none can forgive sin except You.',
 'Bukhari 8:318');

-- ── Duas: Prayer (2) ──────────────────────────────────────────────────────────
INSERT INTO duas (category_id, title_en, arabic, transliteration, translation, reference) VALUES
(2, 'Opening Supplication (Iftitah)',
 'اللَّهُمَّ بَاعِدْ بَيْنِي وَبَيْنَ خَطَايَايَ كَمَا بَاعَدْتَ بَيْنَ الْمَشْرِقِ وَالْمَغْرِبِ، اللَّهُمَّ نَقِّنِي مِنَ الْخَطَايَا كَمَا يُنَقَّى الثَّوْبُ الْأَبْيَضُ مِنَ الدَّنَسِ، اللَّهُمَّ اغْسِلْ خَطَايَايَ بِالْمَاءِ وَالثَّلْجِ وَالْبَرَدِ.',
 'Allahumma baaid bayni wa bayna khataaya kama baadat bainal mashriqi wal maghrib. Allahumma naqqini minal khataaya kama yunaqqath thawbul abyadu minad danas. Allahummaghsil khataaya bil maai wath thalji wal barad.',
 'O Allah, separate me from my sins as You have separated the East from the West. O Allah, cleanse me of my transgressions as the white garment is cleansed of stains. O Allah, wash away my sins with ice and water and frost.',
 'Bukhari 1:711'),

(2, 'Dua after Adhan',
 'اللَّهُمَّ رَبَّ هَذِهِ الدَّعْوَةِ التَّامَّةِ وَالصَّلاَةِ الْقَائِمَةِ، آتِ مُحَمَّداً الْوَسِيلَةَ وَالْفَضِيلَةَ، وَابْعَثْهُ مَقَاماً مَحْمُوداً الَّذِي وَعَدْتَهُ.',
 'Allahumma rabba hadhihid da''watit taammah, wassalaatil qa''imah, aati Muhammadanil wasilata wal fadhilah, wab''ath''hu maqaamam mahmudanilladhi wa''adtah.',
 'O Allah, Lord of this perfect call, and the prayer to be offered, grant Muhammad the privilege (of intercession) and also the eminence, and resurrect him to the praised position that You have promised.',
 'Bukhari 1:589'),

(2, 'Dua when going to the Masjid',
 'اللَّهُمَّ اجْعَلْ فِي قَلْبِي نُوراً، وَفِي لِسَانِي نُوراً، وَاجْعَلْ فِي سَمْعِي نُوراً، وَاجْعَلْ فِي بَصَرِي نُوراً، وَاجْعَلْ مِنْ خَلْفِي نُوراً، وَمِنْ أَمَامِي نُوراً، وَاجْعَلْ مِنْ فَوْقِي نُوراً، وَمِنْ تَحْتِي نُوراً.',
 'Allahumma ij''al fi qalbi nuura, wa fi lisaani nuura, waj''al fi sam''i nuura, waj''al fi basari nuura, waj''al min khalfi nuura, wa min amamii nuura, waj''al min fawqi nuura, wa min tahti nuura.',
 'O Allah, place light in my heart, light in my tongue, light in my hearing, light in my sight, light behind me, light before me, place light above me, and light below me.',
 'Muslim 1:526');

-- ── Duas: Sleep & Waking (3) ─────────────────────────────────────────────────
INSERT INTO duas (category_id, title_en, arabic, transliteration, translation, reference) VALUES
(3, 'Before Sleeping',
 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا.',
 'Bismika Allahumma amutu wa ahya.',
 'In Your name O Allah, I die and I live.',
 'Bukhari 11:113'),

(3, 'Upon Waking',
 'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ.',
 'Alhamdu lillahil ladhi ahyaana ba''da maa amatana wa ilayhinnushur.',
 'All praise is for Allah who gave us life after having taken it from us and unto Him is the resurrection.',
 'Bukhari 11:113'),

(3, 'Dua against bad dreams',
 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ غَضَبِهِ وَعِقَابِهِ وَشَرِّ عِبَادِهِ وَمِنْ هَمَزَاتِ الشَّيَاطِينِ وَأَنْ يَحْضُرُونِ.',
 'A''udhu bikalimatillahit tammati min ghadabihi wa iqaabihi wa sharri ibadihi wa min hamazatish shayateeni wa an yahduroon.',
 'I seek refuge in the Perfect Words of Allah from His anger and His punishment, and from the evil of His slaves, and from the taunts of devils and from their presence.',
 'Abu Dawud 4:12');

-- ── Duas: Food & Drink (4) ───────────────────────────────────────────────────
INSERT INTO duas (category_id, title_en, arabic, transliteration, translation, reference) VALUES
(4, 'Before Eating',
 'بِسْمِ اللَّهِ',
 'Bismillah.',
 'In the name of Allah.',
 'Abu Dawud 3:347'),

(4, 'After Eating',
 'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنَا وَسَقَانَا وَجَعَلَنَا مُسْلِمِينَ.',
 'Alhamdu lillahil ladhi at''amana wa saqaana wa ja''alana muslimeen.',
 'All praise is for Allah who fed us, gave us drink, and made us Muslims.',
 'Abu Dawud 4:213'),

(4, 'If you forget Bismillah before eating',
 'بِسْمِ اللَّهِ فِي أَوَّلِهِ وَآخِرِهِ.',
 'Bismillahi fi awwalihi wa aakhirih.',
 'In the name of Allah at its beginning and end.',
 'Abu Dawud 3:347');

-- ── Duas: Entering & Leaving Home (5) ────────────────────────────────────────
INSERT INTO duas (category_id, title_en, arabic, transliteration, translation, reference) VALUES
(5, 'Entering the Home',
 'بِسْمِ اللَّهِ وَلَجْنَا، وَبِسْمِ اللَّهِ خَرَجْنَا، وَعَلَى اللَّهِ رَبِّنَا تَوَكَّلْنَا.',
 'Bismillahi walajna, wa bismillahi kharajna, wa alallahi rabbina tawakkalna.',
 'In the name of Allah we enter, in the name of Allah we leave, and upon our Lord we place our trust.',
 'Abu Dawud 4:325'),

(5, 'Leaving the Home',
 'بِسْمِ اللَّهِ، تَوَكَّلْتُ عَلَى اللَّهِ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ.',
 'Bismillah, tawakkaltu alallah, wa laa hawla wa laa quwwata illa billah.',
 'In the name of Allah, I place my trust in Allah, and there is no might nor power except with Allah.',
 'Abu Dawud 4:325');

-- ── Duas: Seeking Forgiveness (9) ─────────────────────────────────────────────
INSERT INTO duas (category_id, title_en, arabic, transliteration, translation, reference) VALUES
(9, 'Astaghfirullah',
 'أَسْتَغْفِرُ اللَّهَ',
 'Astaghfirullah.',
 'I seek forgiveness from Allah.',
 'Quran 71:10'),

(9, 'Complete Istighfar',
 'أَسْتَغْفِرُ اللَّهَ الَّذِي لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ وَأَتُوبُ إِلَيْهِ.',
 'Astaghfirullahallazi laa ilaaha illa huwal hayyul qayyumu wa atubu ilayh.',
 'I seek forgiveness from Allah, besides whom there is none worthy of worship, the Ever Living, the One who sustains and protects all that exists, and I turn to Him in repentance.',
 'Abu Dawud 2:85'),

(9, 'Tauba — Repentance',
 'رَبَّنَا ظَلَمْنَا أَنفُسَنَا وَإِن لَّمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنَ الْخَاسِرِينَ.',
 'Rabbana zalamna anfusana wa in lam taghfir lana wa tarhamna lanakunanna minal khasireen.',
 'Our Lord! We have wronged ourselves. If You forgive us not, and bestow not upon us Your Mercy, we shall certainly be of the losers.',
 'Quran 7:23');

-- ── Duas: Gratitude & Praise (10) ─────────────────────────────────────────────
INSERT INTO duas (category_id, title_en, arabic, transliteration, translation, reference) VALUES
(10, 'Alhamdulillah',
 'الْحَمْدُ لِلَّهِ',
 'Alhamdulillah.',
 'All praise is for Allah.',
 'Quran 1:2'),

(10, 'SubhanAllah wa Bihamdihi',
 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
 'SubhanAllahi wa bihamdihi.',
 'Glorified is Allah and praised is He.',
 'Bukhari 7:168'),

(10, 'SubhanAllahil Adheem',
 'سُبْحَانَ اللَّهِ الْعَظِيمِ',
 'SubhanAllahil adheem.',
 'Glorified is Allah, the Most Great.',
 'Bukhari 9:227');

-- ── Duas: Illness & Healing (11) ─────────────────────────────────────────────
INSERT INTO duas (category_id, title_en, arabic, transliteration, translation, reference) VALUES
(11, 'Dua for the Sick',
 'اللَّهُمَّ رَبَّ النَّاسِ، أَذْهِبِ الْبَأْسَ، وَاشْفِ أَنْتَ الشَّافِي، لَا شِفَاءَ إِلَّا شِفَاؤُكَ، شِفَاءً لَا يُغَادِرُ سَقَمَاً.',
 'Allahumma rabban naas, adhhibil ba''sa, washfi antash shaafi, laa shifaa''a illa shifaa''uka, shifaa''an laa yughaadiru saqama.',
 'O Allah, Lord of mankind, remove the affliction and send down cure and healing, for no one can cure but You; so cure in a way that leaves no illness.',
 'Bukhari 7:579'),

(11, 'Ruqyah — Recite over the ill',
 'بِسْمِ اللَّهِ أَرْقِيكَ، مِنْ كُلِّ شَيْءٍ يُؤْذِيكَ، مِنْ شَرِّ كُلِّ نَفْسٍ أَوْ عَيْنٍ حَاسِدٍ، اللَّهُ يَشْفِيكَ، بِسْمِ اللَّهِ أَرْقِيكَ.',
 'Bismillahi arqeek, min kulli shay''in yu''dheek, min sharri kulli nafsin aw aynin haasid, Allahu yashfeek, bismillahi arqeek.',
 'In the name of Allah I perform ruqyah for you, from everything that is harming you, from the evil of every soul or envious eye, may Allah heal you, in the name of Allah I perform ruqyah for you.',
 'Muslim 4:1718');

-- ── Duas: Protection (14) ─────────────────────────────────────────────────────
INSERT INTO duas (category_id, title_en, arabic, transliteration, translation, reference) VALUES
(14, 'Ayat al-Kursi (Throne Verse)',
 'اللَّهُ لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ وَلَا يَئُودُهُ حِفْظُهُمَا وَهُوَ الْعَلِيُّ الْعَظِيمُ.',
 'Allahu laa ilaaha illa huwal hayyul qayyum. Laa ta''khdhuhu sinatuw wa laa nawm. Lahu maa fis samaawaati wa maa fil ardh. Man dhal ladhi yashfa''u indahu illa bi idhnih. Ya''lamu maa bayna aydeehim wa maa khalfahum. Wa laa yuheetoona bi shay''im min ilmihi illaa bi maa shaa''a wasi''a kursiyyuhus samaawaati wal ardh. Wa laa ya''uduhu hifdhuhumaa wa huwal aliyyul adheem.',
 'Allah! There is none worthy of worship but He, the Ever Living, the One Who sustains and protects all that exists. Neither slumber, nor sleep overtake Him. To Him belongs whatever is in the Heavens and whatever is on Earth. Who is he that can intercede with Him except with His Permission? He knows what happens to them (His creatures) in this world, and what will happen to them in the Hereafter. And they will never compass anything of His Knowledge except that which He wills. His Kursi extends over the Heavens and the Earth, and He feels no fatigue in guarding and preserving them. And He is the Most High, the Most Great.',
 'Quran 2:255'),

(14, 'Al-Mu''awwidhat — Al-Ikhlas, Al-Falaq, An-Nas',
 'قُلْ هُوَ اللَّهُ أَحَدٌ',
 'Qul huwallahu ahad. Allahus samad. Lam yalid wa lam yulad. Wa lam yakun lahu kufuwan ahad.',
 'Say: He is Allah, One! Allah, the eternally Besought of all! He begets not, nor is He begotten. And there is none comparable unto Him.',
 'Quran 112');

-- ── Duas: Miscellaneous Dhikr (15) ────────────────────────────────────────────
INSERT INTO duas (category_id, title_en, arabic, transliteration, translation, reference) VALUES
(15, 'SubhanAllah (33x after prayer)',
 'سُبْحَانَ اللَّهِ',
 'SubhanAllah.',
 'Glorified is Allah.',
 'Muslim 1:418'),

(15, 'Alhamdulillah (33x after prayer)',
 'الْحَمْدُ لِلَّهِ',
 'Alhamdulillah.',
 'All praise is for Allah.',
 'Muslim 1:418'),

(15, 'Allahu Akbar (34x after prayer)',
 'اللَّهُ أَكْبَرُ',
 'Allahu akbar.',
 'Allah is the greatest.',
 'Muslim 1:418'),

(15, 'La ilaha illallah wahdahu',
 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.',
 'Laa ilaaha illallahu wahdahu laa sharika lah, lahul mulku wa lahul hamdu wa huwa ala kulli shay''in qadeer.',
 'None has the right to be worshipped except Allah, alone, without partner. To Him belongs all sovereignty and praise, and He is over all things omnipotent.',
 'Muslim 4:2071'),

(15, 'Hawqalah',
 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
 'Laa hawla wa laa quwwata illa billah.',
 'There is no power and no might except with Allah.',
 'Bukhari 9:93');

