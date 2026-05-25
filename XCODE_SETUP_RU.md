# Инструкция по настройке Xcode для ByeByeDPI iOS

Пошаговое руководство по настройке проекта в Xcode для запуска на вашем устройстве.

## 📋 Предварительные требования

- macOS 12.0 или новее
- Xcode 14.0 или новее (скачать бесплатно из Mac App Store)
- Apple ID (можно использовать бесплатный аккаунт)
- iPhone или iPad с iOS 14.0+
- Кабель USB для подключения устройства (или настройка Wi-Fi синхронизации)

---

## 🚀 Пошаговая настройка

### Шаг 1: Открытие проекта

1. Запустите терминал и перейдите в директорию проекта:
   ```bash
   cd /путь/к/ByeByeDPI-iOS
   ```

2. Откройте проект в Xcode:
   ```bash
   open ByeByeDPI.xcodeproj
   ```
   
   Или перетащите файл `ByeByeDPI.xcodeproj` на иконку Xcode.

### Шаг 2: Компиляция библиотек

Перед открытием Xcode убедитесь, что библиотеки скомпилированы:

```bash
chmod +x Scripts/build_byedpi.sh
./Scripts/build_byedpi.sh
```

После выполнения в папке `Libraries/` должен появиться файл `libbyedpi.a`.

### Шаг 3: Настройка подписи (Signing)

#### 3.1. Добавьте ваш Apple ID в Xcode

1. В меню выберите **Xcode → Settings** (или **Preferences** на старых версиях)
2. Перейдите на вкладку **Accounts**
3. Нажмите **+** в левом нижнем углу
4. Выберите **Apple ID** и нажмите **Continue**
5. Введите ваш Apple ID и пароль
6. После входа вы увидите вашу команду в списке

#### 3.2. Настройте подписку для основного приложения

1. В навигаторе проектов (слева) выберите самый верхний элемент **ByeByeDPI** (синяя иконка проекта)
2. В центральной панели выберите target **ByeByeDPI** (не проект, а именно target!)
3. Перейдите на вкладку **Signing & Capabilities**
4. В секции **Signing**:
   - ✅ Поставьте галочку **Automatically manage signing**
   - В поле **Team** выберите вашу команду (ваш Apple ID)
   - **Bundle Identifier** должен измениться автоматически (например, `com.yourname.byebyedpi`)

#### 3.3. Настройте подписку для Packet Tunnel Extension

1. В том же окне **Signing & Capabilities** прокрутите вниз до секции **Targets**
2. Выберите target **PacketTunnel**
3. Повторите те же действия:
   - ✅ **Automatically manage signing**
   - Выберите ту же **Team**
   - Bundle Identifier будет вида `com.yourname.byebyedpi.PacketTunnel`

### Шаг 4: Добавление Capabilities

#### 4.1. App Groups (для обоих targets)

App Groups необходимы для обмена данными между приложением и Network Extension.

**Для основного приложения (ByeByeDPI target):**

1. Убедитесь, что выбран target **ByeByeDPI**
2. Вкладка **Signing & Capabilities**
3. Нажмите **+ Capability** в левом верхнем углу
4. Найдите и выберите **App Groups**
5. Появится секция **App Groups**
6. Нажмите **+** под списком групп
7. Введите название группы: `group.com.yourname.byebyedpi`  
   *(Замените `yourname` на ваш идентификатор разработчика)*
8. Нажмите **Enter**

**Для Packet Tunnel extension:**

1. Выберите target **PacketTunnel**
2. Добавьте **App Groups** capability (как выше)
3. Добавьте **ту же самую группу**: `group.com.yourname.byebyedpi`
   - Важно: группа должна быть идентичной!

#### 4.2. Network Extensions (только для PacketTunnel)

1. Убедитесь, что выбран target **PacketTunnel**
2. Нажмите **+ Capability**
3. Найдите и выберите **Network Extensions**
4. В появившейся секции поставьте галочку:
   - ✅ **Packet Tunnel Provider**

### Шаг 5: Проверка настроек Build

#### 5.1. Убедитесь, что библиотеки подключены

1. Выберите target **PacketTunnel**
2. Перейдите на вкладку **Build Phases**
3. Раскройте секцию **Link Binary With Libraries**
4. Должна присутствовать `libbyedpi.a`
   
   Если её нет:
   - Нажмите **+**
   - Выберите **Add Other... → Add Files...**
   - Найдите `Libraries/libbyedpi.a`
   - Нажмите **Add**

#### 5.2. Header Search Paths

1. Выберите target **PacketTunnel**
2. Перейдите на вкладку **Build Settings**
3. В поиске введите `Header Search Paths`
4. Убедитесь, что там указан путь к заголовкам:
   ```
   $(PROJECT_DIR)/ByeDPICore
   $(PROJECT_DIR)/Libraries
   ```

### Шаг 6: Выбор устройства для запуска

1. Подключите ваше iOS устройство к Mac через USB
2. На устройстве разрешите доверие этому компьютеру (если появится запрос)
3. В Xcode в верхней панели, где обычно написано "Any iOS Device", выберите ваше устройство
   - Устройство должно отображаться с названием модели и версией iOS
   - Если устройства нет в списке: **Window → Devices and Simulators**

### Шаг 7: Первый запуск

1. Нажмите **▶ Run** (или `Cmd+R`)
2. При первом запуске Xcode может запросить разрешение на использование ключа разработки - разрешите
3. Дождитесь сборки и установки на устройство
4. На устройстве появится иконка приложения

#### Если появилась ошибка "Untrusted Developer":

1. Откройте **Настройки** на iPhone/iPad
2. Перейдите в **Основные → VPN и управление устройством** (или **Profiles & Device Management**)
3. В разделе **Developer App** найдите ваш Apple ID
4. Нажмите на него и выберите **Доверять "Ваше Имя"**
5. Подтвердите действие
6. Вернитесь на домашний экран и запустите приложение снова

### Шаг 8: Проверка работы

После запуска приложения:

1. ✅ Приложение открылось без ошибок
2. ✅ Кнопка подключения активна
3. ✅ Можно перейти в настройки

При первой попытке подключения:
- Система покажет запрос на добавление VPN конфигурации
- Нажмите **Разрешить** (Allow)
- Введите код-пароль устройства или используйте Face ID/Touch ID

---

## 🔧 Решение проблем

### Ошибка: "No provisioning profiles found"

**Решение:**
1. Убедитесь, что выбран правильный Team в Signing settings
2. Попробуйте отключить и снова включить **Automatically manage signing**
3. Xcode → Settings → Accounts → выберите аккаунт → Download Manual Profiles

### Ошибка: "Bundle identifier cannot be changed"

**Решение:**
1. Измените Bundle Identifier на уникальный (например, добавьте ваше имя)
2. Сделайте это для обоих targets (приложение и PacketTunnel)

### Ошибка: "App Group not found"

**Решение:**
1. Убедитесь, что App Group создан для ОБЕИХ targets
2. Название группы должно совпадать символ в символ
3. Попробуйте удалить и заново добавить capability

### Устройство не определяется в Xcode

**Решение:**
1. Отключите и снова подключите кабель
2. Разблокируйте устройство
3. Проверьте **Window → Devices and Simulators**
4. Перезапустите Xcode
5. Попробуйте другой USB порт

### PacketTunnel не запускается

**Решение:**
1. Проверьте, что Network Extensions capability добавлен
2. Убедитесь, что libbyedpi.a подключена к PacketTunnel target
3. Проверьте логи в Console.app на Mac

### Приложение падает при подключении

**Решение:**
1. Проверьте консоль устройств на ошибки
2. Убедитесь, что App Groups настроены правильно
3. Попробуйте удалить приложение и установить заново

---

## 📱 Тестирование на разных устройствах

Для тестирования на нескольких устройствах:

1. Подключите каждое устройство хотя бы один раз
2. Xcode запомнит их
3. Переключайтесь между устройствами в верхней панели

Можно также использовать **Wi-Fi синхронизацию**:
1. Подключите устройство по USB
2. В Finder (или iTunes) выберите устройство
3. Поставьте галочку **Sync with this device over Wi-Fi**
4. Теперь устройство будет доступно без кабеля (в той же сети)

---

## 🏗 Сборка архива (для распространения)

Для создания IPA файла:

1. Выберите схему **ByeByeDPI**
2. В верхней панели выберите **Any iOS Device (arm64)** вместо конкретного устройства
3. Меню **Product → Archive**
4. После сборки откроется окно **Organizer**
5. Выберите архив и нажмите **Distribute App**
6. Выберите метод распространения:
   - **Ad Hoc** - для установки на конкретные устройства
   - **Development** - для личной разработки
   - **Enterprise** - только для корпоративных аккаунтов

---

## 📚 Дополнительные ресурсы

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Network Extension Programming Guide](https://developer.apple.com/documentation/networkextension)
- [Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/)
- [App Groups Documentation](https://developer.apple.com/documentation/security/keychain_services/keychain_items/sharing_access_to_keychain_items_among_a_collection_of_apps)

---

## ✅ Чек-лист успешной настройки

- [ ] Xcode установлен и запущен
- [ ] Apple ID добавлен в Accounts
- [ ] Проект открыт в Xcode
- [ ] Библиотеки скомпилированы (`libbyedpi.a` существует)
- [ ] Team выбран для обоих targets
- [ ] Bundle Identifiers уникальны
- [ ] App Groups добавлен и настроен для обоих targets
- [ ] Network Extensions добавлен для PacketTunnel
- [ ] Устройство подключено и выбрано для запуска
- [ ] Проект собирается без ошибок
- [ ] Приложение запускается на устройстве
- [ ] VPN подключение работает

Если все пункты отмечены - поздравляем! 🎉 Проект готов к разработке и тестированию!

---

*Последнее обновление: 2024*
