# mirzabot_shell_exec-fix# 🔒 امن‌سازی `shell_exec` در ربات میرزا پنل

اسکریپتی برای امن‌سازی ربات `botmirzapanel` از طریق مدیریت امن تابع `shell_exec` برای کرون جاب‌ها.

این پروژه یک اسکریپت برای حل مشکل امنیتی تابع `shell_exec` در ربات‌های مبتنی بر «میرزا پنل» ارائه می‌دهد. این اسکریپت به صورت خودکار فایل‌های ناامن را با نسخه‌های امن جایگزین کرده و تنظیمات لازم را روی سرور اعمال می‌کند.

---

## 🚀 راهنمای شروع سریع

برای حل مشکل امنیتی `shell_exec`، لطفاً مراحل زیر را به ترتیب انجام دهید.

### ۱. ورود به سرور شما
به ترمینال سرور خود متصل شوید (معمولاً از طریق **SSH**).

### ۲. رفتن به پوشه ربات
با دستور `cd` به پوشه ربات مورد نظر خود بروید.

```bash
# مثال:
cd /www/wwwroot/your-domain.com/telegram_bot/bot_folder_name
```

### ۳. اجرای اسکریپت نصب
دستور زیر را کپی کرده و در ترمینال خود پیست کنید و اینتر را بزنید. اسکریпт به صورت خودکار همه چیز را مدیریت می‌کند.

```bash
curl -sSL https://raw.githubusercontent.com/vahid162/mirzabot_shell_exec-fix/main/installer.sh | sudo bash
```


### ۴. غیرفعال کردن `shell_exec`
این **مهم‌ترین قدم نهایی** برای بستن حفره امنیتی است.

سرور شما اکنون امن و کاملاً کاربردی است!



**تغییرات به صورت دستی**


# راهنمای کامل امن‌سازی ربات تلگرام (botmirzapanel) و تابع `shell_exec`

🔒 این راهنما به شما نشان می‌دهد که چطور تابع خطرناک `shell_exec` را در PHP غیرفعال کنید و همزمان به ربات تلگرام خود اجازه دهید تا کارهای مدیریتی (مانند تنظیم کرون‌جاب‌ها) را به شکلی کاملاً امن انجام دهد.

### **مشکل چیست؟ (The "Why")**

تابع `shell_exec` به PHP اجازه می‌دهد دستورات را مستقیماً روی سرور لینوکس اجرا کند. اگر این تابع فعال باشد و یک هکر راهی برای نفوذ به کد شما پیدا کند، می‌تواند کنترل کامل سرور را به دست بگیرد. راه حل ما این است که این تابع را در PHP غیرفعال کنیم، اما از طریق یک اسکریپت واسط امن و با استفاده از `sudo` در لینوکس، فقط به دستورات مشخصی که ربات نیاز دارد، اجازه اجرا بدهیم.

### **پیش‌نیازها (Prerequisites)**

* دسترسی به ترمینال سرور (معمولاً از طریق SSH).
* دسترسی به کاربر `root` یا کاربری با دسترسی `sudo`.
* دانستن مسیر نصب ربات (مثلاً: `/www/wwwroot/yourdomain.com/telegram_bot/your_bot_folder/`).
* یک ویرایشگر متن در ترمینال مانند `nano`.

---

### **قدم اول: ساخت اسکریپت واسط امن (`cron_helper.sh`)**

این اسکریپت به عنوان یک دروازه‌بان امن عمل می‌کند و فقط دستورات مربوط به کرون‌جاب را اجرا می‌کند.

1.  با دستور زیر، فایل اسکریپت را در مسیر استاندارد و امن `/usr/local/bin/` بسازید:
    ```bash
    sudo nano /usr/local/bin/cron_helper.sh
    ```

2.  کد زیر را به طور کامل کپی کرده و داخل ویرایشگر `nano` پیست (Paste) کنید:
    ```bash
    #!/bin/bash
    # --- Secure Cron Job Helper Script ---
    # Allows adding or removing specific cron jobs safely.

    set -e

    ACTION=$1
    JOB_COMMAND="${@:2}" # Get all arguments starting from the second one

    # --- Basic Validation ---
    # Ensure the job command is a valid cron job starting with curl.
    if [[ "$ACTION" == "add" && ! "$JOB_COMMAND" =~ ^\*\/\d+\s+\*\s+\*\s+\*\s+\*\s+curl\s+https:\/\/.*$ ]]; then
        echo "Error: Invalid or insecure cron job command provided." >&2
        exit 1
    fi

    case "$ACTION" in
        add)
            (crontab -l 2>/dev/null | grep -vF -- "$JOB_COMMAND" ; echo "$JOB_COMMAND") | crontab -
            ;;
        remove)
            (crontab -l 2>/dev/null | grep -vF -- "$JOB_COMMAND") | crontab -
            ;;
        list)
            crontab -l
            ;;
        *)
            echo "Error: Invalid action. Use 'add', 'remove', or 'list'." >&2
            exit 1
            ;;
    esac

    exit 0
    ```

3.  فایل را ذخیره کنید. در `nano`، با زدن `Ctrl+X`، سپس `Y` و در آخر `Enter` این کار را انجام دهید.

---

### **قدم دوم: تنظیم دسترسی‌های صحیح**

این دستورات تضمین می‌کنند که اسکریپت فقط توسط کاربر ریشه (`root`) قابل تغییر است و توسط کاربر وب‌سرور قابل اجراست.

```bash
sudo chown root:root /usr/local/bin/cron_helper.sh
sudo chmod 750 /usr/local/bin/cron_helper.sh
```

---

### **قدم سوم: تنظیم قانون `sudo`**

به کاربر وب‌سرور (معمولاً `www-data` در اوبونتو/دبیان) اجازه می‌دهیم که فقط اسکریپت ما را بدون نیاز به پسورد اجرا کند.

1.  دستور زیر را برای ویرایش امن فایل `sudoers` وارد کنید:
    ```bash
    sudo visudo
    ```

2.  با کیبورد به **انتهای فایل** بروید و این خط را دقیقاً اضافه کنید:
    ```
    www-data ALL=(root) NOPASSWD: /usr/local/bin/cron_helper.sh
    ```

3.  فایل را ذخیره کرده و خارج شوید (`Ctrl+X`، سپس `Y` و `Enter`).

---

### **قدم چهارم: اصلاح فایل‌های PHP ربات**

📝 در این مرحله، کدهای ناامن ربات را با فراخوانی‌های امن به اسکریپت واسط خودمان جایگزین می‌کنیم. این کار باید برای تمام پوشه‌های ربات تکرار شود.

#### **الف) اصلاح `index.php`**

* **فایل را باز کنید:** `nano /path/to/your_bot_folder/index.php`
* **این بلاک کد را پیدا کنید (SEARCH FOR THIS):**
    ```php
    if (function_exists('shell_exec') && is_callable('shell_exec')) {
    $existingCronCommands = shell_exec('crontab -l');
    $phpFilePath = "https://$domainhosts/cron/sendmessage.php";
    $cronCommand = "*/1 * * * * curl $phpFilePath";
    if (strpos($existingCronCommands, $cronCommand) === false) {
        $command = "(crontab -l ; echo '$cronCommand') | crontab -";
        shell_exec($command);
    }
    }
    ```
* **کل بلاک بالا را با این کد جایگزین کنید (REPLACE WITH THIS):**
    ```php
    if (function_exists('shell_exec') && is_callable('shell_exec')) {
        $phpFilePath = "https://{$domainhosts}/cron/sendmessage.php";
        $cronCommand = "*/1 * * * * curl {$phpFilePath}";
        shell_exec("sudo /usr/local/bin/cron_helper.sh add " . escapeshellarg($cronCommand));
    }
    ```

#### **ب) اصلاح `admin.php`**

* **فایل را باز کنید:** `nano /path/to/your_bot_folder/admin.php`
* **۱. حذف بررسی اولیه:** بلاک کد زیر را که معمولاً در **ابتدای فایل** است، پیدا کرده و **کامل حذف کنید**:
    ```php
    // vvv DELETE THIS ENTIRE BLOCK vvv
    if(!(function_exists('shell_exec') && is_callable('shell_exec'))){
        $cronCommandsendmessage = "*/1 * * * * curl https://$domainhosts/cron/sendmessage.php";
        sendmessage($from_id, sprintf($textbotlang['Admin']['cron']['active_manual_sendmessage'],$cronCommandsendmessage),null, 'HTML');
    }
    ```
* **۲. حذف بررسی ثانویه (داخل منوی کرون‌جاب):**
    * **این بلاک کد را پیدا کنید (SEARCH FOR THIS):**
        ```php
        if ($text == $textbotlang['Admin']['keyboardadmin']['settingscron']) {
            if(!(function_exists('shell_exec') && is_callable('shell_exec'))){
                $crontest = "...";
                // ... (lines to build the error message)
                sendmessage($from_id, sprintf($textbotlang['Admin']['cron']['active_manual'],$crontest,$cronvolume,$crontime,$cronremove), null, 'HTML');
                return;
            }
            sendmessage($from_id, $textbotlang['users']['selectoption'], $keyboardcronjob, 'HTML');
        }
        ```
    * **کل بلاک بالا را با این کد جایگزین کنید (REPLACE WITH THIS):**
        ```php
        if ($text == $textbotlang['Admin']['keyboardadmin']['settingscron']) {
            sendmessage($from_id, $textbotlang['users']['selectoption'], $keyboardcronjob, 'HTML');
        }
        ```
* **۳. اصلاح کدهای فعال/غیرفعال‌سازی کرون‌جاب:** در ادامه فایل `admin.php`، چهار بخش برای مدیریت کرون‌جاب‌ها وجود دارد. الگوی اصلاح آنها یکسان است.

    * **برای فعال‌سازی (مانند `configtest`):**
        * **کد قبلی:** `shell_exec($command);`
        * **کد جدید:** `shell_exec("sudo /usr/local/bin/cron_helper.sh add " . escapeshellarg($cronCommand));`
    * **برای غیرفعال‌سازی (مانند `configtest`):**
        * **بلاک کد چندخطی قبلی را پیدا و حذف کنید.**
        * **کد جدید (فقط یک خط):**
            ```php
            $jobToRemove = "*/15 * * * * curl https://$domainhosts/cron/configtest.php";
            shell_exec("sudo /usr/local/bin/cron_helper.sh remove " . escapeshellarg($jobToRemove));
            ```

    این الگو را برای هر چهار کرون‌جاب (`test`, `volume`, `time`, `remove`) تکرار کنید.

---

### **قدم پنجم: غیرفعال کردن نهایی `shell_exec`**

این آخرین و مهم‌ترین قدم برای بستن حفره امنیتی است.



---

### **قدم ششم: تست و تأیید نهایی ✅**

1.  وارد ربات تلگرام خود شده و به پنل ادمین بروید.
2.  به بخش "تنظیمات کرون جاب" (`settingscron`) بروید. این بار نباید پیام خطا ببینید و منوی مدیریت باید نمایش داده شود.
3.  یکی از کرون‌جاب‌ها را فعال یا غیرفعال کنید.
4.  اگر پیام موفقیت‌آمیز دریافت کردید، یعنی تمام مراحل به درستی انجام شده است.

🚀 با انجام این مراحل، ربات شما اکنون هم کارایی خود را حفظ کرده و هم در برابر حملات مربوط به `shell_exec` کاملاً امن شده است.
