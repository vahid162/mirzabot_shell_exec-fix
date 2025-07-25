# mirzabot_shell_exec-fix
A script to secure the botmirzapanel by safely managing shell_exec for cron jobs

برای حل مشکل امنیتی shell_exec، لطفاً مراحل زیر را به ترتیب انجام دهید.

۱. ورود به ترمینال:
وارد ترمینال سرور خود شوید.

۲. رفتن به پوشه ربات:
با دستور cd به پوشه ربات مورد نظر خود بروید.

۳. اجرای دستور جادویی:

curl -sSL https://raw.githubusercontent.com/vahid162/mirzabot_shell_exec-fix/refs/heads/main/fix_bot.sh | sudo bash


 اسکریپت به صورت خودکار تمام کارها را انجام می‌دهد.

 ۵. غیرفعال کردن shell_exec
