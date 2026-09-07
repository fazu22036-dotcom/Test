import logging
from telegram import Update
from telegram.ext import ApplicationBuilder, ContextTypes, CommandHandler

# فعال‌سازی لاگ‌ها برای دیدن خطاهای احتمالی
logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)

# تابع شروع و خوش‌آمدگویی
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_name = update.effective_user.first_name
    welcome_message = f"سلام {user_name} عزیز!\nبه ربات ما خوش آمدید. 😊"
    await update.message.reply_text(welcome_message)

def main():
    # توکن ربات خود را اینجا وارد کنید
    TOKEN = "8525496066:AAFezIaZLFQEZId1l-jr3LRui2EvDYkKosI"
    
    # ساخت اپلیکیشن ربات
    application = ApplicationBuilder().token(TOKEN).build()
    
    # ثبت دستور استارت
    start_handler = CommandHandler('start', start)
    application.add_handler(start_handler)
    
    # اجرای ربات (به صورت Long Polling)
    print("ربات در حال اجراست...")
    application.run_polling()

if __name__ == '__main__':
    main()
