# 🦊 Рыжик — обучающая игра о диабете 1 типа

Игра для детей 5–7 лет. Лисёнок Рыжик попадает в разные ситуации,
ребёнок помогает ему справиться и учится правильным действиям.

---

## Быстрый старт

### 1. Установить Godot 4

Скачать: https://godotengine.org/download  
Нужна версия **4.2+** (Stable).

### 2. Открыть проект

```
Godot → Import → выбрать папку ryzhik/ → project.godot
```

### 3. Настроить экспорт Android

В Godot: **Project → Export → Add → Android**

Нужно установить:
- **Android SDK** (через Android Studio или sdkmanager)
- **JDK 17+** (https://adoptium.net)
- **Android Build Tools** в Godot: Editor → Editor Settings → Export → Android

Путь к SDK обычно:
- Windows: `C:\Users\<user>\AppData\Local\Android\Sdk`
- macOS: `~/Library/Android/sdk`
- Linux: `~/Android/Sdk`

### 4. Запустить в редакторе

Нажать **F5** или кнопку ▶️ в правом верхнем углу.

---

## Структура проекта

```
ryzhik/
├── autoload/
│   ├── GameState.gd        ← прогресс игрока, сохранение
│   └── AudioManager.gd     ← централизованный звук
│
├── characters/
│   ├── Ryzhik.tscn         ← персонаж (создать в редакторе)
│   └── ryzhik_controller.gd
│
├── episodes/
│   ├── episode_base.gd     ← базовый класс всех эпизодов
│   └── ep01_after_slide/
│       ├── EP01_AfterSlide.tscn   ← создать в редакторе
│       └── ep01.gd
│
├── minigames/
│   ├── GlucometerTap.gd
│   ├── ChoiceCards.gd
│   └── SugarMeter.gd
│
├── scenes/
│   ├── EpisodeMap.tscn     ← создать в редакторе
│   ├── EpisodeMap.gd
│   └── ResultScreen.gd
│
├── data/
│   └── episodes.json       ← весь контент (тексты, ситуации)
│
└── assets/
    ├── fonts/              ← положить Nunito.ttf
    ├── sounds/             ← .ogg файлы
    └── sprites/            ← .png спрайты Рыжика
```

---

## Первые шаги в редакторе

После открытия проекта нужно создать сцены вручную.
Код уже написан — осталось собрать дерево узлов.

### Сцена Ryzhik.tscn

```
Node2D (ryzhik_controller.gd)
├── AnimatedSprite2D         ← спрайты Рыжика
├── AnimationPlayer          ← анимации: idle, tired, happy, talking
├── SpeechBubble (CanvasLayer)
│   └── Panel
│       └── Label            ← текст пузыря
└── StatusIcon (Label)       ← эмодзи состояния
```

### Сцена EP01_AfterSlide.tscn

```
Node2D (ep01.gd)
├── Background (TextureRect или ColorRect)
├── Ryzhik.tscn              ← инстанс персонажа
├── Minigames (Node)
│   ├── GlucometerTap.tscn
│   └── ChoiceCards.tscn
└── UI (CanvasLayer)
    ├── TopBar
    │   └── ProgressBar
    ├── SugarMeter.tscn
    ├── StoryCard (Panel)
    │   ├── StoryLabel (RichTextLabel)
    │   └── NextButton (Button)
    └── ResultScreen.tscn
```

### Сцена EpisodeMap.tscn

```
Node2D (EpisodeMap.gd)
├── Background
├── EpisodeButtons (Node)
│   ├── ep01 (Button)
│   ├── ep02 (Button)
│   └── ... (6 кнопок с именами ep01..ep06)
└── UI (CanvasLayer)
    └── Header
        └── TotalStars (Label)
```

---

## Добавление звуков

Положить в `assets/sounds/` файлы .ogg:
- `tap.ogg`
- `correct.ogg`
- `wrong.ogg`
- `star.ogg`
- `glucometer.ogg`
- `juice.ogg`
- `complete.ogg`
- `music_menu.ogg`
- `music_episode.ogg`

Бесплатные звуки: https://freesound.org | https://opengameart.org

---

## Добавление спрайтов Рыжика

AnimatedSprite2D нужны анимации:
- `idle`       — спокойный (2–4 кадра)
- `tired`      — вялый (2 кадра)
- `happy`      — радостный (4 кадра)
- `talking`    — говорит (2 кадра)
- `drink_juice`— пьёт сок (4 кадра)

Можно начать с плейсхолдеров (цветные прямоугольники) и заменить позже.

---

## FAQ

**Q: Как добавить новый эпизод?**  
A: Создать папку `episodes/ep04_sports/`, скопировать ep01.gd, поменять контент.
Добавить в `EpisodeMap.gd` в словари `EPISODE_ORDER`, `EPISODE_SCENES`, `EPISODE_TITLES`.

**Q: Как изменить тексты без кода?**  
A: Редактировать `data/episodes.json` — все тексты там.
(Для полного использования JSON нужно подключить EpisodeLoader.gd — следующий шаг.)

**Q: Как собрать APK?**  
A: Project → Export → Android → Export Project → выбрать папку.
Для Google Play нужен подписанный APK (настройки в Export → Android → Keystore).
