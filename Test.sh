من یک سورس کد ربات تلگرام به زبان پایتون دارم که برای اجرا روی سرور لینوکس (VPS) نوشته شده است. از تو می‌خواهم این کد را به طور کامل و دقیق، بدون حذف یا خلاصه کردن هیچ یک از امکانات، به یک Cloudflare Worker (فایل worker.js) بر پایه استاندارد جاوااسکریپت (V8 Engine) تبدیل کنی.

⚠️ الزامات فنی و منطقی بسیار مهم که باید دقیقاً رعایت کنی:

1. حل مشکل دانلود لینک‌ها (بدون هارد دیسک): در کلودفلر ورکرز امکان استفاده از yt-dlp یا ذخیره فایل روی هارد وجود ندارد. بخش پردازش لینک را به گونه‌ای بازنویسی کن که از یک API کمکی ابری و پایدار (مانند API پلتفرم Cobalt به آدرس https://co.wuk.sh/api/json) استفاده کند تا پیوندها را آنالیز کرده و لینک دانلود مستقیم صوتی (MP3) و ویدیویی (MP4) را به صورت دکمه‌های شیشه‌ای به کاربر تحویل دهد. همچنین ساختار آلبوم‌های چندتایی (مثل مینی‌البوم‌های اینستاگرام یا تیک‌تاک) را هندل کند.

2. پایگاه داده (Cloudflare KV): تمام بخش‌های ذخیره‌سازی داده (مانند وضعیت کاربر، آمار، بخش VIP، کاربران مسدود شده و قفل کانال) را به دیتابیس Cloudflare KV متصل کن. فرض کن دیتابیس با نام متغیر env.BOT_DB در دسترس است.

3. ساختار ضد کرش (Anti-Crash): تمام فرآیندهای خواندن و نوشتن در دیتابیس KV را درون بلوک‌های امنیتی try {} catch(e) {} قرار بده تا اگر دیتابیس در پنل کلودفلر Bind نشده بود، ورکر کرش نکند و ربات همچنان استارت شود و منوها را باز کند.

4. سیستم مدیریت وضعیت (State Management): برای فرآیندهای چند مرحله‌ای ادمین (مانند افزودن VIP ترکیبی که به ترتیب آیدی عددی، حجم مجاز به مگابایت و تعداد روز را می‌گیرد، یا بخش مسدودسازی و پیام همگانی)، از ذخیره وضعیت در دیتابیس KV با کلید `action:userId` استفاده کن.

5. ارتباط دوطرفه با پشتیبانی: بخش ارسال پیام کاربر به ادمین و دکمه شیشه‌ای "✍️ پاسخ مستقیم" ادمین به کاربر را دقیقاً پیاده‌سازی کن تا ادمین بتواند مستقیماً روی پیام کاربر کلیک کرده و پاسخ دهد.

6. قفل کانال جوین اجباری پویا: امکان تنظیم آیدی کانال اسپانسر توسط ادمین و بررسی وضعیت عضویت کاربر با متد getChatMember تلگرام را به صورت کاملاً پویا قرار بده. اگر کاربر عضو نبود منوی شیشه‌ای اخطار عضویت همراه با دکمه بررسی مجدد باز شود و با ارسال کلمه "حذف" توسط ادمین، قفل کاملاً باز شود.

7. سیستم استاندارد ۴ زبانه: ساختار متنی دکمه‌ها و پیام‌ها را بر اساس یک آبجکت ثابت به نام STRINGS به ۴ زبان (فارسی صمیمی و استاندارد، انگلیسی، ترکی و روسی) پیاده‌سازی کن که زبان پیش‌فرض آن فارسی باشد.

8. فرمت خروجی: کد نهایی را به صورت یکپارچه، کامل، بدون خلاصه کردن بخش‌ها یا گذاشتن کامنت‌های راهنما بجای کد واقعی، به صورت آماده برای کپی کردن در فایل worker.js به من تحویل بده.

این کد اصلی پایتون من است، منطق آن را دقیقاً به جاوااسکریپت کلودفلر تبدیل کن:

[اینجا کدهای اصلی پایتون خود را پیست کنید]





#!/bin/bash
# ═══════════════════════════════════════════════════════════
#   🤖 Universal Downloader Bot - Master Pro Ultimate SUPER EDITION
#   پنل مدیریت ارشد، سیستم VIP ترکیبی (عددی/حروفی)، قفل چند کاناله اسپانسر
#   [نسخه ارتقا یافته تام: ۴ زبانه، مانیتورینگ زنده، منوی شیشه‌ای همزمان]
# ═══════════════════════════════════════════════════════════

# ─── Colors ─────────────────────────────────────────────────
R='\033[0;31m'  G='\033[0;32m'
Y='\033[1;33m'  C='\033[0;36m'
B='\033[1m'     N='\033[0m'

clear
echo -e "${C}${B}"
cat << 'BANNER'
╔══════════════════════════════════════════════╗
║   🤖 Ultimate Downloader Bot - Super Pro V6  ║
║      Premium Persian Tone & Quad-Language    ║
╚══════════════════════════════════════════════╝
BANNER
echo -e "${N}"

# ─── Get Bot Credentials ────────────────────────────────────
echo -e "${Y}🔑 توکن ربات تلگرامت رو وارد کن:${N}"
read -p "   TOKEN: " BOT_TOKEN

if [ -z "$BOT_TOKEN" ]; then
    echo -e "${R}❌ توکن خالی است!${N}"
    exit 1
fi

echo -e "\n${Y}🆔 شناسه API_ID (از سایت my.telegram.org):${N}"
read -p "   API_ID: " TELEGRAM_API_ID

if [ -z "$TELEGRAM_API_ID" ]; then
    echo -e "${R}❌ وارد کردن API_ID الزامی است!${N}"
    exit 1
fi

echo -e "\n${Y}🔑 هش API_HASH (از سایت my.telegram.org):${N}"
read -p "   API_HASH: " TELEGRAM_API_HASH

if [ -z "$TELEGRAM_API_HASH" ]; then
    echo -e "${R}❌ وارد کردن API_HASH الزامی است!${N}"
    exit 1
fi

echo -e "\n${Y}👤 آیدی عددی خودت ادمین بزرگ:${N}"
read -p "   ADMIN_ID: " ADMIN_ID

if [ -z "$ADMIN_ID" ]; then
    echo -e "${R}❌ وارد کردن آیدی عددی ادمین الزامی است!${N}"
    exit 1
fi

# ─── Setup Directory ────────────────────────────────────────
BOT_DIR="$HOME/downloader-bot"
mkdir -p "$BOT_DIR/downloads"
cd "$BOT_DIR"

# ════════════════════════════════════════════════════════════
#  راه‌اندازی سرور محلی تلگرام (Docker & Local Bot API)
# ════════════════════════════════════════════════════════════
echo -e "\n${Y}🐳 در حال بررسی و راه‌اندازی سرور محلی تلگرام...${N}"

if ! command -v docker &> /dev/null; then
    echo -e "${C}🔄 داکر نصب نیست. در حال نصب خودکار داکر...${N}"
    curl -fsSL https://get.docker.com | sh
    sudo systemctl start docker
    sudo systemctl enable docker
fi

docker stop telegram-bot-api &> /dev/null
docker rm telegram-bot-api &> /dev/null

docker run -d \
  --name telegram-bot-api \
  --restart always \
  -p 8081:8081 \
  -v telegram-bot-api-data:/var/lib/telegram-bot-api \
  -e TELEGRAM_API_ID="${TELEGRAM_API_ID}" \
  -e TELEGRAM_API_HASH="${TELEGRAM_API_HASH}" \
  aiogram/telegram-bot-api:latest

echo -e "${G}✅ سرور محلی تلگرام روی پورت 8081 فعال شد.${N}"

# ════════════════════════════════════════════════════════════
#  بررسی و نصب FFmpeg جهت تبدیل فرمت‌ها
# ════════════════════════════════════════════════════════════
if ! command -v ffmpeg &> /dev/null; then
    echo -e "${C}🔄 اف‌ام‌پگ نصب نیست. در حال نصب ffmpeg...${N}"
    sudo apt-get update && sudo apt-get install -y ffmpeg
fi

# ════════════════════════════════════════════════════════════
#  ساخت فایل .env
# ════════════════════════════════════════════════════════════
cat > .env << EOF
BOT_TOKEN=${BOT_TOKEN}
ADMIN_IDS=${ADMIN_ID}
TELEGRAM_API_ID=${TELEGRAM_API_ID}
TELEGRAM_API_HASH=${TELEGRAM_API_HASH}
EOF

# ════════════════════════════════════════════════════════════
#  ساخت فایل config.py (تغییر کامل متون به رسمی و جامع)
# ════════════════════════════════════════════════════════════
cat > config.py << 'PYEOF'
import os
from dotenv import load_dotenv
load_dotenv()

BOT_TOKEN   = os.getenv("BOT_TOKEN", "")
ADMIN_IDS   = list(map(int, os.getenv("ADMIN_IDS", "0").split(",")))

DOWNLOAD_PATH    = "./downloads"
MAX_FILE_SIZE    = 2 * 1024 * 1024 * 1024  # 2GB Telegram hard limit
DEFAULT_USER_LIMIT = 200 * 1024 * 1024     # 200MB default limit for normal users

SUPPORTED_PLATFORMS = {
    "youtube":     {"emoji": "🎬", "name": "YouTube"},
    "pornhub":     {"emoji": "🔞", "name": "Pornhub"},
    "instagram":   {"emoji": "📸", "name": "Instagram"},
    "twitter":     {"emoji": "🐦", "name": "Twitter/X"},
    "x.com":       {"emoji": "🐦", "name": "Twitter/X"},
    "tiktok":      {"emoji": "🎵", "name": "TikTok"},
    "pinterest":   {"emoji": "📌", "name": "Pinterest"},
    "facebook":    {"emoji": "👥", "name": "Facebook"},
    "vimeo":       {"emoji": "🎥", "name": "Vimeo"},
    "reddit":      {"emoji": "🤖", "name": "Reddit"},
    "twitch":      {"emoji": "🎮", "name": "Twitch"},
    "soundcloud":  {"emoji": "🎵", "name": "SoundCloud"},
    "aparat":      {"emoji": "🎬", "name": "Aparat"},
    "spotify":     {"emoji": "🎵", "name": "Spotify"},
    "apple":       {"emoji": "🍏", "name": "Apple Music"},
}

VIDEO_QUALITIES = {
    "best":  {"label_fa": "🏆 بهترین کیفیت موجود", "label_en": "🏆 Best Quality", "label_tr": "🏆 En İyi Kalite", "label_ru": "🏆 Лучшее качество", "format": "bestvideo[ext=mp4][vcodec^=avc1]+bestaudio[ext=m4a]/bestvideo+bestaudio/best"},
    "1080p": {"label_fa": "📺 کیفیت عالی 1080p Full HD", "label_en": "📺 1080p Full HD", "label_tr": "📺 1080p Tam HD", "label_ru": "📺 1080p Full HD", "format": "bestvideo[height<=1080][ext=mp4][vcodec^=avc1]+bestaudio[ext=m4a]/bestvideo[height<=1080]+bestaudio/best[height<=1080]/best"},
    "720p":  {"label_fa": "🖥️ کیفیت بالا 720p HD", "label_en": "🖥️ 720p HD", "label_tr": "🖥️ 720p HD Yüksek", "label_ru": "🖥️ 720p HD Высокое", "format": "bestvideo[height<=720][ext=mp4][vcodec^=avc1]+bestaudio[ext=m4a]/bestvideo[height<=720]+bestaudio/best[height<=720]/best"},
    "480p":  {"label_fa": "📱 کیفیت متوسط 480p", "label_en": "📱 480p Medium", "label_tr": "📱 480p Orta", "label_ru": "📱 480p Среднее", "format": "bestvideo[height<=480][ext=mp4][vcodec^=avc1]+bestaudio[ext=m4a]/bestvideo[height<=480]+bestaudio/best[height<=480]/best"},
    "360p":  {"label_fa": "💾 کیفیت کم‌حجم 360p", "label_en": "💾 360p Low Size", "label_tr": "💾 360p Düşük Boyut", "label_ru": "💾 360p Низкий размер", "format": "bestvideo[height<=360][ext=mp4][vcodec^=avc1]+bestaudio[ext=m4a]/bestvideo[height<=360]+bestaudio/best[height<=360]/best"},
    "mp3":   {"label_fa": "🎵 استخراج فایل صوتی MP3 (کیفیت بالا)", "label_en": "🎵 Extract High MP3", "label_tr": "🎵 Yüksek Kalite MP3 Çıkar", "label_ru": "🎵 Извлечь MP3 Высокое", "format": "bestaudio/best"},
    "m4a":   {"label_fa": "🎵 استخراج فایل صوتی M4A (کم‌حجم)", "label_en": "🎵 Extract Light M4A", "label_tr": "🎵 Hafif M4A Çıkar", "label_ru": "🎵 Извлечь M4A Легкое", "format": "bestaudio/best"},
    "photo": {"label_fa": "🖼️ دانلود پوستر / عکس رسانه", "label_en": "🖼️ Download Thumbnail", "label_tr": "🖼️ Küçük Resmi İndir", "label_ru": "🖼️ Скачать обложку", "format": "best"},
}

STRINGS = {
    "fa": {
        "welcome": "سلام و درود بی‌کران محضر شما کاربر گرامی و گران‌قدر، جناب **{name}** عزیز. به ربات هوشمند، پیشرفته و مقتدر دانلودر چندمنظوره بسیار خوش آمدید. افتخار میزبانی از شما مایه خرسندی ماست. ❤️\n\nاین ربات دستیار همه‌فن‌حریف شما برای استخراج و دانلود آنی انواع فایل‌ها و رسانه‌ها از محبوب‌ترین پلتفرم‌های جهانی می‌باشد. کافی است لینک مورد نظر خود را کپی کرده و به صورت مستقیم در کادر پیام برای ربات ارسال نمایید تا شاهکار مهندسی سرور ما آغاز گردد.\n\n⚠️ توجه ملوکانه: جهت حفظ کامل حریم خصوصی شما و بهینه‌سازی دیسک سرور، فایل‌ها بلافاصله پس از تحویل، کاملاً حذف می‌گردند.",
        "help": "📖 *راهنمای جامع کارایی و نحوه بهره‌برداری از ربات:*\n\n1️⃣ **کپی کردن لینک:** لینک ویدیو یا رسانه مورد نظر را از برنامه مبدا (مانند اینستاگرام، یوتیوب، اسپاتیفای و...) کپی فرمایید.\n2️⃣ **ارسال به پیشگاه ربات:** لینک کپی شده را در همین جا ارسال کنید.\n3️⃣ **انتخاب فرمت و کیفیت:** منویی شیک شامل کیفیت‌های متنوع و فایل صوتی به شما نمایش داده می‌شود.\n4️⃣ **تحویل آنی:** با کلیک روی گزینه دلخواه، ربات فایل را استخراج کرده و با قابلیت استریم (پخش آنلاین) برای شما ارسال می‌دارد.\n\n📌 *امکانات فرعی:* با استفاده از دکمه‌های زیر می‌توانید وضعیت اشتراک، آیدی عددی و قوانین را بررسی فرمایید.",
        "btn_contact": "🗣️ ارتباط مهرآمیز با پشتیبانی",
        "btn_lang": "🌐 تغییر زبان سیستم / Language",
        "btn_stats": "📊 وضعیت حساب و شناسه کاربر",
        "btn_status": "⚙️ وضعیت سخت‌افزاری سرور",
        "btn_admin": "💼 پنل مدیریت ارشد ربات",
        "btn_help": "📖 راهنمای کارایی ربات",
        "btn_premium": "👑 خرید اشتراک ویژه / ارتقای حجم VIP",
        "btn_rules": "📜 قوانین و مقررات ربات",
        "msg_premium_plans": "👑 *تعرفه‌های طلایی تهیه اشتراک ویژه و افزایش ظرفیت دانلود:*\n━━━━━━━━━━━━━━━━━━━━\n🎁 **حساب کاربری پایه:** سقف حجم دانلود محدود برای هر فایل (**رایگان**)\n💎 **پلن ۱ گیگابایتی VIP:** افزایش سقف حجم دانلود هر فایل تا ۱ گیگابایت با بالاترین سرعت سرور ➔ **قیمت: ۱۱۰ هزار تومان**\n💎 **پلن ۲ گیگابایتی VIP (کامل):** برداشته شدن تمام محدودیت‌ها تا سقف نهایی تلگرام (۲ گیگابایت کامل) ➔ **قیمت: ۲۰۰ هزار تومان**\n━━━━━━━━━━━━━━━━━━━━\n💬 جهت تهیه اشتراک و ارتقای آنی ظرفیت دانلود حساب خود، لطفاً از طریق دکمه *«🗣️ ارتباط مهرآمیز با پشتیبانی»* با مدیریت سیستم در ارتباط باشید تا با کمال میل راهنمایی شوید.",
        "msg_rules": "📜 *قوانین و مقررات انضباطی استفاده از ربات:*\n━━━━━━━━━━━━━━━━━━━━\n۱. **عدم ارسال اسپم:** لطفا از ارسال رگباری و مکرر لینک‌ها جهت حفظ ثبات سرور خودداری فرمایید.\n۲. **حفظ ادب و احترام:** هرگونه فحاشی، مزاحمت یا بی‌احترامی در بخش پشتیبانی منجر به مسدودسازی دائم و بدون بازگشت حساب شما خواهد شد.\n۳. **حقوق سرور:** دانلود فایل‌های مخرب یا ناقض قوانین سایبری بین‌المللی ممنوع می‌باشد.\n━━━━━━━━━━━━━━━━━━━━\n✨ بیایید با رعایت قوانین، فضایی امن و پایدار بسازیم.",
        "msg_analyzing": "⏳ سیستم با دقت بالا در حال بررسی و آنالیز پیوند ارسالی شماست. لطفاً چند لحظه شکیبا باشید...",
        "msg_direct_file": "📦 لینک مستقیم دانلود فایل شناسایی شد. فرآیند دریافت فایل روی سرور آغاز گردید...",
        "msg_downloading": "⬇️ در حال دانلود و استخراج رسانه از سرور مبدا به حافظه موقت ربات...",
        "msg_uploading": "📤 فرآیند دانلود پایان یافت. در حال بهینه‌سازی و آپلود مستقیم فایل در محیط تلگرام شما هستیم...",
        "msg_success": "✅ فرآیند با موفقیت انجام شد! فایل درخواستی تقدیم حضور گردید. از انتخاب شما سپاسگزاریم. ❤️",
        "msg_err_size": "❌ کاربر گرامی، حجم فایل درخواستی از سقف مجاز تعیین شده برای حساب کاربری شما بیشتر است!\nسقف مجاز حساب شما: {limit}\n\n👑 جهت ارتقای حساب خود، می‌توانید گزینه **«👑 خرید اشتراک ویژه / ارتقای حجم VIP»** را بررسی فرمایید.",
        "msg_err_generic": "❌ متأسفانه خطایی در پردازش لینک رخ داده است. لطفاً از صحت لینک مطمئن شده و مجدداً تلاش فرمایید.",
        "msg_ask_admin": "💬 لطفاً پیام، پیشنهاد یا گزارش مشکل خود را به صورت مکتوب ارسال نمایید تا مستقیماً در اختیار مدیریت قرار گیرد:",
        "msg_sent_to_admin": "✅ پیام شما با موفقیت برای مدیریت سیستم ارسال گردید. لطفاً تا بررسی و پاسخ مدیریت شکیبا باشید.",
        "msg_cancel": "❌ انصراف و بازگشت به منوی اصلی",
        "media_info_title": "📋 *مشخصات فنی رسانه یافت شده:*\n━━━━━━━━━━━━━━━━━━━━\n🎬 *عنوان رسانه:* {title}\n👤 *منبع / ناشر:* {uploader}\n⏱️ *مدت زمان:* {dur}\n━━━━━━━━━━━━━━━━━━━━\n🎛️ *لطفاً کیفیت یا فرمت خروجی مورد نظر خود را جهت دانلود انتخاب نمایید:*"
    },
    "en": {
        "welcome": "Hello and warm welcome dear user, **{name}**. Welcome to the Advanced Universal Downloader Bot. ❤️\n\nThis bot is a professional and automated system designed to download media (videos, images, audio, and direct files) from popular international platforms including YouTube, Instagram, Twitter (X), TikTok, Spotify, Apple Music, and more.\n\nSimply copy and send your link directly into the chat to begin processing.\n\n⚠️ Note: All downloaded files are permanently deleted from the server storage immediately after delivery.",
        "help": "📖 *Comprehensive Bot Guide & Functionality:*\n\n1️⃣ **Copy the Link:** Go to your desired platform and copy the link.\n2️⃣ **Send to Bot:** Paste and send the copied link here.\n3️⃣ **Select Quality:** Choose video quality or audio format from the menu.\n4️⃣ **Receive the File:** Click on your preferred option, and the bot will deliver the file with streaming support.",
        "btn_contact": "🗣️ Contact Support / Send Message",
        "btn_lang": "🌐 Change Language / تغییر زبان",
        "btn_stats": "📊 Account Status & User ID",
        "btn_status": "⚙️ System Hardware Status",
        "btn_admin": "💼 Super Admin Panel",
        "btn_help": "📖 Bot Guide",
        "btn_premium": "👑 Buy Premium / VIP Upgrade",
        "btn_rules": "📜 Bot Rules & Terms",
        "msg_premium_plans": "👑 *VIP Subscription Plans & Size Upgrades:*\n━━━━━━━━━━━━━━━━━━━━\n🎁 **Standard Account:** Limited download size per file (**Free**)\n💎 **1 GB Plan VIP:** Max size 1GB per file with highest priority ➔ **Price: 110,000 Tomans**\n💎 **2 GB Plan VIP (Full):** Max size up to Telegram limit (2GB Complete) ➔ **Price: 200,000 Tomans**\n━━━━━━━━━━━━━━━━━━━━\n💬 To upgrade, please tap on *«🗣️ Contact Support / Send Message»* and contact us.",
        "msg_rules": "📜 *Bot Rules & Regulations:*\n━━━━━━━━━━━━━━━━━━━━\n1. **No Spamming:** Please avoid sending links repeatedly to keep the server stable.\n2. **Respect Support:** Any insults or bad behavior toward the support team will lead to a permanent ban.\n3. **Server Safety:** Downloading malicious or illegal contents is strictly forbidden.\n━━━━━━━━━━━━━━━━━━━━",
        "msg_analyzing": "⏳ Dynamically analyzing your link, please stand by...",
        "msg_direct_file": "📦 Direct file download link detected. Fetching file onto the server...",
        "msg_downloading": "⬇️ Downloading media from the source platform to the server cache...",
        "msg_uploading": "📤 Download finished! Optimizing and uploading the file directly to Telegram...",
        "msg_success": "✅ Successfully processed! Your file has been delivered. Thank you for using our service. ❤️",
        "msg_err_size": "❌ Sorry, this file exceeds the size limit allowed for your account type!\nYour current limit: {limit}\n\n👑 Tap on **«👑 Buy Premium / VIP Upgrade»** to increase your download capacity.",
        "msg_err_generic": "❌ Oops! Something went wrong while processing the link. Ensure it is valid and try again.",
        "msg_ask_admin": "💬 Please type your message or bug report here to forward it directly to the support team:",
        "msg_sent_to_admin": "✅ Your message has been successfully forwarded to the administration. Please await a reply.",
        "msg_cancel": "❌ Cancel and Back to Main Menu",
        "media_info_title": "📋 *Media Technical Information Found:*\n━━━━━━━━━━━━━━━━━━━━\n🎬 *Title:* {title}\n👤 *Source/Uploader:* {uploader}\n⏱️ *Duration:* {dur}\n━━━━━━━━━━━━━━━━━━━━\n🎛️ *Please select your preferred output quality or format below:*"
    },
    "tr": {
        "welcome": "Merhaba ve hoş geldiniz sevgili kullanıcı, **{name}**. Gelişmiş Çok Amaçlı İndirme Botuna hoş geldiniz. ❤️\n\nBu bot; YouTube, Instagram, Twitter (X), TikTok, Spotify, Apple Music ve daha birçok popüler platformdan medya indirmek için tasarlanmıştır.\n\nİşlemi başlatmak için bağlantınızı buraya göndermeniz yeterlidir.",
        "help": "📖 *Bot Kullanım Kılavuzu:*\n\n1️⃣ İstediğiniz platformdan bağlantıyı kopyalayın.\n2️⃣ Kopyalanan bağlantıyı bota gönderin.\n3️⃣ Açılan menüden kalite veya formatı seçin.\n4️⃣ Dosyanızı anında teslim alın.",
        "btn_contact": "🗣️ Destek ile İletişim / Mesaj Gönder",
        "btn_lang": "🌐 Dili Değiştir / Change Language",
        "btn_stats": "📊 Hesap Durumu ve Kullanıcı ID",
        "btn_status": "⚙️ Sistem Donanım Durumu",
        "btn_admin": "💼 Süper Yönetici Paneli",
        "btn_help": "📖 Bot Kılavuzu",
        "btn_premium": "👑 VIP Üyelik Satın Al / Limit Yükselt",
        "btn_rules": "📜 Bot Kullanım Kuralları",
        "msg_premium_plans": "👑 *VIP Abonelik Paketleri ve Sınır Yükseltmeleri:*\n━━━━━━━━━━━━━━━━━━━━\n🎁 **Standart Hesap:** Dosya başına sınırlı boyut (**Ücretsiz**)\n💎 **1 GB VIP Paketi:** Dosya başına 1 GB limit ve yüksek hız ➔ **Fiyat: 110.000 Tümen**\n💎 **2 GB VIP Paketi (Tam):** Maksimum Telegram sınırına kadar (2GB Tam) ➔ **Fiyat: 200.000 Tümen**\n━━━━━━━━━━━━━━━━━━━━\n💬 Satın almak veya yükseltmek için lütfen destek ekibiyle iletişime geçin.",
        "msg_rules": "📜 *Bot Kullanım Kuralları:*\n━━━━━━━━━━━━━━━━━━━━\n1. **Spam Yasaktır:** Sunucu kararlılığını korumak için lütfen üst üste link göndermeyin.\n2. **Saygılı Olun:** Destek ekibine hakaret veya küfür edilmesi kalıcı engelleme sebebidir.\n3. **Güvenlik:** Zararlı veya yasa dışı içeriklerin indirilmesi kesinlikle yasaktır.\n━━━━━━━━━━━━━━━━━━━━",
        "msg_analyzing": "⏳ Bağlantı analiz ediliyor, lütfen bekleyin...",
        "msg_direct_file": "📦 Doğrudان dosya indirme linki algılandı. Sunucuya çekiliyor...",
        "msg_downloading": "⬇️ Medya kaynak platformdan sunucu önbelleğine indiriliyor...",
        "msg_uploading": "📤 İndirme tamamlandı! Optimize ediliyor ve Telegram'a yükleniyor...",
        "msg_success": "✅ İşlem başarıyla tamamlandı! Dosyanız teslim edildi. ❤️",
        "msg_err_size": "❌ Bu dosya hesabınızın indirme sınırını aşıyor!\nSınırınız: {limit}",
        "msg_err_generic": "❌ Bağlantı işlenirken bir hata oluştu. Lütfen tekrar deneyin.",
        "msg_ask_admin": "💬 Lütfen mesajınızı buraya yazın, doğrudan yönetime iletilecektir:",
        "msg_sent_to_admin": "✅ Mesajınız başarıyla yönetime iletildi. Lütfen yanıt bekleyin.",
        "msg_cancel": "❌ İptal Et ve Ana Menüye Dön",
        "media_info_title": "📋 *Medya Bilgileri:*\n━━━━━━━━━━━━━━━━━━━━\n🎬 *Başlık:* {title}\n👤 *Yayıncı:* {uploader}\n⏱️ *Süre:* {dur}\n━━━━━━━━━━━━━━━━━━━━\n🎛️ *Lütfen indirmek istediğiniz formatı seçin:*"
    },
    "ru": {
        "welcome": "Здравствуйте и добро пожаловать, уважаемый пользователь **{name}**. Рады видеть вас в продвинутом универсальном загрузчике. ❤️\n\nЭтот бот предназначен для автоматического скачивания медиа из YouTube, Instagram, Twitter (X), TikTok, Spotify, Apple Music и других платформ.\n\nПросто отправьте ссылку в чат, чтобы начать обработку.",
        "help": "📖 *Руководство пользователя:*\n\n1️⃣ Скопируйте ссылку на медиафайл.\n2️⃣ Отправьте скопированную ссылку боту.\n3️⃣ Выберите желаемое качество или формат в меню.\n4️⃣ Получите файл прямо в чат с поддержкой онлайн-просмотра.",
        "btn_contact": "🗣️ Связаться с поддержкой",
        "btn_lang": "🌐 Изменить язык / Change Language",
        "btn_stats": "📊 Статус аккаунта и ID",
        "btn_status": "⚙️ Состояние сервера",
        "btn_admin": "💼 Панель администратора",
        "btn_help": "📖 Руководство",
        "btn_premium": "👑 Купить VIP-подписку",
        "btn_rules": "📜 Правила использования",
        "msg_premium_plans": "👑 *VIP Тарифы и Увеличение Лимитов:*\n━━━━━━━━━━━━━━━━━━━━\n🎁 **Обычный аккаунт:** Ограниченный размер файла (**Бесплатно**)\n💎 **Тариф VIP 1 ГБ:** Лимит до 1 ГБ на файл и максимальная скорость ➔ **Цена: 110 000 томанов**\n💎 **Тариф VIP 2 ГБ (Полный):** Полный лимит до лимита Telegram (2 ГБ) ➔ **Цена: 200 000 томанов**\n━━━━━━━━━━━━━━━━━━━━\n💬 Для покупки или активации тарифа свяжитесь с поддержкой.",
        "msg_rules": "📜 *Правила использования бота:*\n━━━━━━━━━━━━━━━━━━━━\n1. **Без спама:** Пожалуйста, не отправляйте ссылки слишком часто, чтобы не перегружать сервер.\n2. **Уважение:** Любые оскорбления в адрес поддержки приведут к вечной блокировке.\n3. **Безопасность:** Запрещено скачивать вредоносные ссылки.",
        "msg_analyzing": "⏳ Анализ ссылки, пожалуйста, подождите...",
        "msg_direct_file": "📦 Обнаружена прямая ссылка на файл. Загрузка на сервер...",
        "msg_downloading": "⬇️ Скачивание медиа с платформы на сервер...",
        "msg_uploading": "📤 Скачивание завершено! Файл оптимизируется и загружается в Telegram...",
        "msg_success": "✅ Файл успешно обработан и доставлен! Спасибо за использование. ❤️",
        "msg_err_size": "❌ Этот файл превышает лимит вашего аккаунта!\nВаш лимит: {limit}",
        "msg_err_generic": "❌ Произошла ошибка при обработке ссылки. Убедитесь в её корректности.",
        "msg_ask_admin": "💬 Введите ваше сообщение для администрации:",
        "msg_sent_to_admin": "✅ Ваше сообщение успешно отправлено администрации.",
        "msg_cancel": "❌ Отмена и возврат в главное меню",
        "media_info_title": "📋 *Техническая информация:*\n━━━━━━━━━━━━━━━━━━━━\n🎬 *Название:* {title}\n👤 *Автор:* {uploader}\n⏱️ *Длительность:* {dur}\n━━━━━━━━━━━━━━━━━━━━\n🎛️ *Выберите формат для скачивания:*"
    }
}
PYEOF

# ════════════════════════════════════════════════════════════
#  ساخت فایل اصلی bot.py (سیستم VIP حروفی/عددی و قفل چندکاناله)
# ════════════════════════════════════════════════════════════
cat > bot.py << 'PYEOF'
#!/usr/bin/env python3
import os, re, sys, time, uuid, asyncio, logging, json, shutil, subprocess
from datetime import datetime
from pathlib import Path
from typing import Optional, Dict, Any, Tuple, List

import yt_dlp
import humanize
import httpx
import psutil  
from rich.console import Console
from rich.logging import RichHandler
from rich.panel import Panel

from telegram import (
    Update, InlineKeyboardButton,
    InlineKeyboardMarkup, ReplyKeyboardMarkup,
)
from telegram.ext import (
    Application, CommandHandler,
    MessageHandler, CallbackQueryHandler,
    ContextTypes, filters,
)
from telegram.constants import ParseMode, ChatAction

import config

console = Console()
logging.basicConfig(
    level=logging.INFO, format="%(message)s", datefmt="[%X]",
    handlers=[RichHandler(console=console, rich_tracebacks=True, markup=True, show_path=False)]
)
log = logging.getLogger("DLBot")
logging.getLogger("httpx").setLevel(logging.WARNING)
logging.getLogger("telegram").setLevel(logging.WARNING)

class PersistentStats:
    def __init__(self):
        self.file_path = "bot_stats_v4.json"
        self.load()
        
    def load(self):
        if os.path.exists(self.file_path):
            try:
                with open(self.file_path, "r") as f:
                    data = json.load(f)
                    self.users = set(str(u) for u in data.get("users", []))
                    self.banned_users = set(str(u) for u in data.get("banned_users", []))
                    self.vip_users = data.get("vip_users", {})
                    self.username_to_id = data.get("username_to_id", {})
                    self.total = data.get("total", 0)
                    self.ok = data.get("ok", 0)
                    self.fail = data.get("fail", 0)
                    self.size = data.get("size", 0)
                    self.user_langs = data.get("user_langs", {})
                    self.maintenance = data.get("maintenance", False)
                    self.force_channels = data.get("force_channels", [])
                    if "force_join" in data and data["force_join"] and data["force_join"] not in self.force_channels:
                        self.force_channels.append(data["force_join"])
                    self.normal_limit = data.get("normal_limit", config.DEFAULT_USER_LIMIT) 
            except Exception:
                self.reset()
        else:
            self.reset()
        self.started = datetime.now()

    def reset(self):
        self.users = set()
        self.banned_users = set()
        self.vip_users = {}
        self.username_to_id = {}
        self.total = self.ok = self.fail = self.size = 0
        self.user_langs = {}
        self.maintenance = False
        self.force_channels = []
        self.normal_limit = config.DEFAULT_USER_LIMIT
        self.save()

    def save(self):
        try:
            with open(self.file_path, "w") as f:
                json.dump({
                    "users": list(self.users),
                    "banned_users": list(self.banned_users),
                    "vip_users": self.vip_users,
                    "username_to_id": self.username_to_id,
                    "total": self.total,
                    "ok": self.ok,
                    "fail": self.fail,
                    "size": self.size,
                    "user_langs": self.user_langs,
                    "maintenance": self.maintenance,
                    "force_channels": self.force_channels,
                    "normal_limit": self.normal_limit
                }, f)
        except Exception as e:
            log.error(f"Error saving stats: {e}")

    def add_user(self, user_id: int, username: Optional[str] = None):
        uid_str = str(user_id)
        if uid_str not in self.users:
            self.users.add(uid_str)
        if uid_str not in self.user_langs:
            self.user_langs[uid_str] = "fa"
        if username:
            clean_user = username.strip().replace("@", "").lower()
            self.username_to_id[clean_user] = uid_str
        self.save()

    def resolve_user_id(self, input_str: str) -> Optional[str]:
        cleaned = input_str.strip().replace("@", "")
        if cleaned.isdigit():
            return cleaned
        return self.username_to_id.get(cleaned.lower())

    def get_lang(self, user_id: int) -> str:
        return self.user_langs.get(str(user_id), "fa")

    def set_lang(self, user_id: int, lang: str):
        self.user_langs[str(user_id)] = lang
        self.save()

    def ban(self, user_id: str) -> bool:
        self.banned_users.add(str(user_id).strip())
        self.save()
        return True

    def unban(self, user_id: str) -> bool:
        uid = str(user_id).strip()
        if uid in self.banned_users:
            self.banned_users.remove(uid)
            self.save()
            return True
        return False

    def add_vip(self, user_id: str, limit_bytes: int) -> bool:
        self.vip_users[str(user_id).strip()] = limit_bytes
        self.save()
        return True

    def remove_vip(self, user_id: str) -> bool:
        uid = str(user_id).strip()
        if uid in self.vip_users:
            del self.vip_users[uid]
            self.save()
            return True
        return False

    def success(self, s=0): 
        self.total += 1
        self.ok += 1
        self.size += s
        self.save()

    def failure(self): 
        self.total += 1
        self.fail += 1
        self.save()

    def uptime(self):
        d = datetime.now() - self.started
        h, r = divmod(int(d.total_seconds()), 3600)
        m, s = divmod(r, 60)
        return f"{h:02d}:{m:02d}:{s:02d}"

class Downloader:
    def __init__(self):
        self.path = Path(config.DOWNLOAD_PATH)
        self.path.mkdir(parents=True, exist_ok=True)

    def is_url(self, text: str) -> bool:
        return bool(re.match(r'^https?://', text.strip(), re.I))

    def detect_platform(self, url: str) -> str:
        u = url.lower()
        for k, v in config.SUPPORTED_PLATFORMS.items():
            if k in u: return f"{v['emoji']} {v['name']}"
        return "🌐 لینک دانلود مستقیم یا وب‌سایت آنلاین"

    def ensure_faststart(self, file_path: str) -> str:
        if not file_path or not os.path.exists(file_path): 
            return file_path
        if not file_path.lower().endswith('.mp4'): 
            return file_path
        
        tmp_path = file_path + ".fs.mp4"
        try:
            cmd = ["ffmpeg", "-y", "-i", file_path, "-c", "copy", "-movflags", "+faststart", tmp_path]
            res = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=30)
            if res.returncode == 0 and os.path.exists(tmp_path) and os.path.getsize(tmp_path) > 0:
                os.remove(file_path)
                os.rename(tmp_path, file_path)
                log.info(f"Stream-Optimized FastStart applied to: {file_path}")
        except Exception as e:
            log.error(f"Error applying FastStart optimization: {e}")
            if os.path.exists(tmp_path):
                try: os.remove(tmp_path)
                except: pass
        return file_path

    def get_info(self, url: str) -> Optional[Dict]:
        opts = {
            "quiet": True, "no_warnings": True, "socket_timeout": 30,
            "nocheckcertificate": True, "ignoreerrors": True,
            "age_limit": 99, "no_playlist": True,
            "http_headers": {
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, Gecko) Chrome/122.0.0.0 Safari/537.36",
                "Referer": "https://www.google.com/", "Accept": "*/*"
            }
        }
        try:
            with yt_dlp.YoutubeDL(opts) as ydl: 
                info = ydl.extract_info(url, download=False)
                if info and "entries" in info:
                    entries = list(info["entries"])
                    if entries and entries[0]: return entries[0]
                return info
        except Exception as e:
            log.error(f"Extraction error: {e}")
            return None

    def format_info(self, info: Dict, lang: str) -> str:
        s = config.STRINGS[lang]
        title    = (info.get("title","نامشخص") or "نامشخص")[:50]
        uploader = info.get("uploader", info.get("channel","نامشخص")) or "نامشخص"
        duration = info.get("duration", 0) or 0
        if duration:
            m, s_time = divmod(int(duration), 60)
            h, m = divmod(m, 60)
            dur = f"{h:02d}:{m:02d}:{s_time:02d}" if h else f"{m:02d}:{s_time:02d}"
        else: dur = "Live stream 📺" if lang != "fa" else "پخش زنده آنلاین رسانه 📺"
        return s["media_info_title"].format(title=title, uploader=uploader, dur=dur)

    def download(self, url: str, quality: str) -> Optional[str]:
        uid = str(uuid.uuid4())[:8]
        out = str(self.path / f"{uid}_%(title).40s.%(ext)s")
        
        if quality == "photo":
            opts = {"skip_download": True, "writethumbnail": True, "outtmpl": str(self.path / f"{uid}_video"), "quiet": True, "no_warnings": True, "nocheckcertificate": True, "restrictfilenames": True}
            with yt_dlp.YoutubeDL(opts) as ydl: ydl.download([url])
            for f in self.path.iterdir():
                if uid in f.name: return str(f)
            return None

        fmt = config.VIDEO_QUALITIES.get(quality, config.VIDEO_QUALITIES["best"])["format"]
        if "pornhub" in url.lower() and quality not in ["mp3", "m4a", "photo"]:
            fmt = "best"

        formats_to_try = [fmt, "best/bestvideo+bestaudio"]
        if quality in ["mp3", "m4a"]: formats_to_try = ["bestaudio/best"]
            
        for current_fmt in formats_to_try:
            pps = []
            if quality == "mp3": pps.append({"key": "FFmpegExtractAudio", "preferredcodec": "mp3", "preferredquality": "320"})
            elif quality == "m4a": pps.append({"key": "FFmpegExtractAudio", "preferredcodec": "m4a"})
                
            opts = {
                "format": current_fmt, "outtmpl": out, "merge_output_format": "mp4" if quality not in ["mp3", "m4a"] else None,
                "quiet": True, "no_warnings": True, "socket_timeout": 60, "retries": 5,
                "postprocessors": pps, "max_filesize": config.MAX_FILE_SIZE, "nocheckcertificate": True, "ignoreerrors": True,
                "restrictfilenames": True, "age_limit": 99, "no_playlist": True,
                "http_headers": {
                    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, Gecko) Chrome/122.0.0.0 Safari/537.36",
                    "Referer": url, "Accept": "*/*"
                },
            }
            try:
                with yt_dlp.YoutubeDL(opts) as ydl: ydl.download([url])
                for f in self.path.iterdir():
                    if uid in f.name: 
                        if quality not in ["mp3", "m4a", "photo"]:
                            return self.ensure_faststart(str(f))
                        return str(f)
            except Exception: pass
        return None

    async def check_direct_file(self, url: str) -> Tuple[bool, str, str]:
        strict_file_exts = ['.apk', '.exe', '.zip', '.rar', '.iso', '.jpeg', '.png', '.jpg', '.webp', '.wpeg', '.txt', '.py', '.sh', '.pdf', '.bin', '.doc', '.docx', '.xapk', '.apks']
        filename = url.split("/")[-1].split("?")[0]
        ext = os.path.splitext(filename)[1].lower()
        if any(ext == e for e in strict_file_exts): return True, filename, ext
        try:
            async with httpx.AsyncClient(timeout=10, follow_redirects=True, verify=False) as client:
                resp = await client.head(url, headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"})
                if resp.status_code >= 400:
                    resp = await client.get(url, headers={"Range": "bytes=0-1", "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}, verify=False)
                ct = resp.headers.get("Content-Type", "").lower()
                if "text/html" in ct or "video" in ct or "audio" in ct or "mpegurl" in ct or "m3u8" in ct: return False, filename, ext
                return True, filename, ext
        except Exception: pass
        if ext and ext not in ['.html', '.htm', '.php', '.asp', '.aspx']: return True, filename, ext
        return False, filename, ext

    def download_generic_file(self, url: str) -> Optional[Tuple[str, str]]:
        uid = str(uuid.uuid4())[:8]
        filename = url.split("/")[-1].split("?")[0]
        if not filename or len(filename) < 3: filename = f"file_{uid}.bin"
        out_path = str(self.path / f"{uid}_{filename}")
        try:
            headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)", "Referer": url}
            with httpx.stream("GET", url, follow_redirects=True, timeout=60, headers=headers, verify=False) as r:
                r.raise_for_status()
                with open(out_path, "wb") as f:
                    for chunk in r.iter_bytes(chunk_size=32768): f.write(chunk)
            return out_path, filename
        except Exception: return None

    def cleanup(self, path: str):
        try:
            if path and os.path.exists(path): 
                os.remove(path)
                log.info(f"🗑️ حافظه سرور پاکسازی شد: {path}")
        except Exception as e: 
            log.error(f"Error during file cleanup: {e}")

dl     = Downloader()
stats  = PersistentStats()

async def check_force_join_status(ctx: ContextTypes.DEFAULT_TYPE, user_id: int) -> Tuple[bool, List[str]]:
    if not stats.force_channels: return True, []
    if user_id in config.ADMIN_IDS: return True, []
    
    unjoined_channels = []
    for channel in stats.force_channels:
        try:
            chat_target = channel
            if not (channel.startswith("-100") or channel.isdigit()):
                chat_target = f"@{channel}"
            member = await ctx.bot.get_chat_member(chat_id=chat_target, user_id=user_id)
            if member.status not in ['creator', 'administrator', 'member', 'restricted']:
                unjoined_channels.append(channel)
        except Exception:
            unjoined_channels.append(channel)
            
    if unjoined_channels:
        return False, unjoined_channels
    return True, []

def find_action(text: str) -> Optional[str]:
    for lang, mapping in config.STRINGS.items():
        for key, val in mapping.items():
            if val == text: return key
    return None

def main_reply_keyboard(user_id: int, lang: str) -> ReplyKeyboardMarkup:
    s = config.STRINGS[lang]
    buttons = [
        [s["btn_stats"], s["btn_status"]],
        [s["btn_contact"], s["btn_lang"]],
        [s["btn_premium"], s["btn_help"]],
        [s["btn_rules"]]
    ]
    if user_id in config.ADMIN_IDS: buttons.append([s["btn_admin"]])
    return ReplyKeyboardMarkup(buttons, resize_keyboard=True)

def main_inline_keyboard(lang: str) -> InlineKeyboardMarkup:
    s = config.STRINGS[lang]
    return InlineKeyboardMarkup([
        [InlineKeyboardButton(s["btn_stats"], callback_data="menu:stats"), InlineKeyboardButton(s["btn_status"], callback_data="menu:status")],
        [InlineKeyboardButton(s["btn_premium"], callback_data="menu:premium"), InlineKeyboardButton(s["btn_help"], callback_data="menu:help")],
        [InlineKeyboardButton(s["btn_rules"], callback_data="menu:rules"), InlineKeyboardButton("🌐 Language", callback_data="btn_lang_inline")]
    ])

def quality_keyboard(lang: str) -> InlineKeyboardMarkup:
    rows = []
    items = list(config.VIDEO_QUALITIES.items())
    label_key = f"label_{lang}" if f"label_{lang}" in items[0][1] else "label_fa"
    for i in range(0, len(items), 2):
        row = []
        for key, val in items[i:i+2]: row.append(InlineKeyboardButton(val.get(label_key, val["label_fa"]), callback_data=f"q:{key}"))
        rows.append(row)
    rows.append([InlineKeyboardButton(config.STRINGS[lang]["msg_cancel"], callback_data="cancel")])
    return InlineKeyboardMarkup(rows)

def lang_keyboard() -> InlineKeyboardMarkup:
    return InlineKeyboardMarkup([
        [InlineKeyboardButton("🇮🇷 فارسی", callback_data="lang:fa"), InlineKeyboardButton("🇺🇸 English", callback_data="lang:en")],
        [InlineKeyboardButton("🇹🇷 Türkçe", callback_data="lang:tr"), InlineKeyboardButton("🇷🇺 Русский", callback_data="lang:ru")]
    ])

def super_giant_admin_keyboard() -> InlineKeyboardMarkup:
    m_status = "🔴 فعال (قفل)" if stats.maintenance else "🟢 غیرفعال (باز)"
    limit_label = f"📦 سقف عادی: {humanize.naturalsize(stats.normal_limit)}"
    return InlineKeyboardMarkup([
        [InlineKeyboardButton("📢 ارسال متن همگانی", callback_data="adm:bc_text"), InlineKeyboardButton("🔄 بنر/کپی همگانی", callback_data="adm:bc_copy")],
        [InlineKeyboardButton("🚫 بن کردن کاربر", callback_data="adm:ban"), InlineKeyboardButton("🟢 بخشش کاربر", callback_data="adm:unban")],
        [InlineKeyboardButton("💎 ارتقا به VIP حجمی", callback_data="adm:add_vip"), InlineKeyboardButton("💔 حذف کاربر از VIP", callback_data="adm:rem_vip")],
        [InlineKeyboardButton("🔍 آنالیز وضعیت کاربر", callback_data="adm:inspect_user"), InlineKeyboardButton("📢 مدیریت کانال‌های اسپانسر", callback_data="adm:manage_fj")],
        [InlineKeyboardButton(f"{limit_label}", callback_data="adm:set_lim"), InlineKeyboardButton(f"🛠️ تعمیرات: {m_status}", callback_data="adm:toggle_maint")],
        [InlineKeyboardButton("🗑️ پاکسازی آنی فایل‌های دانلود شده (آزادکننده هارد)", callback_data="adm:clean")],
        [InlineKeyboardButton("📁 دریافت فایل دیتابیس", callback_data="adm:get_db"), InlineKeyboardButton("🔄 ریست آمار", callback_data="adm:reset_all")],
        [InlineKeyboardButton("❌ بستن پنل", callback_data="admin:close")]
    ])

async def send_admin_panel(chat_id, ctx, message_id=None):
    cpu = psutil.cpu_percent()
    ram = psutil.virtual_memory().percent
    total_disk, used_disk, free_disk = shutil.disk_usage(".")
    disk_percent = round((used_disk / total_disk) * 100, 1)
    
    def make_bar(p):
        filled = int(p // 10)
        return f"├{'█'*filled}{'░'*(10-filled)}┤ {p}%"

    dl_dir = Path(config.DOWNLOAD_PATH)
    dl_files_count = 0
    dl_dir_size = 0
    if dl_dir.exists():
        for f in dl_dir.glob("*"):
            if f.is_file():
                dl_files_count += 1
                dl_dir_size += f.stat().st_size
    
    msg = (
        f"👑 *پنل مدیریت ارشد و مانیتورینگ هوشمند سرور* 👑\n\n"
        f"📊 **مشخصات و وضعیت زنده منابع سخت‌افزاری:**\n"
        f"━━━━━━━━━━━━━━━━━━━━\n"
        f"🔥 *مصرف پردازنده (CPU):*\n"
        f"`{make_bar(cpu)}`\n\n"
        f"📟 *مصرف حافظه موقت (RAM):*\n"
        f"`{make_bar(ram)}`\n\n"
        f"💽 *وضعیت کل دیسک سرور (HDD/SSD):*\n"
        f"`{make_bar(disk_percent)}`\n"
        f"   🔹 کل هارد سرور: `{humanize.naturalsize(total_disk)}`\n"
        f"   🔹 فضای کاملاً آزاد: `{humanize.naturalsize(free_disk)}`\n"
        f"   🔹 فضای مصرف‌شده: `{humanize.naturalsize(used_disk)}`\n\n"
        f"📂 *وضعیت پوشه دانلود کاربران (`/downloads`):*\n"
        f"   🔸 حجم کل فایل‌های موجود در دیسک: `{humanize.naturalsize(dl_dir_size)}`\n"
        f"   🔸 تعداد فایل‌های معلق در حافظه: `{dl_files_count} فایل`\n"
        f"━━━━━━━━━━━━━━━━━━━━\n"
        f"📈 *آمار حیاتی دیتابیس و ربات:*\n"
        f"👥 کل کاربران دیتابیس: `{len(stats.users)}` | 🛑 لیست سیاه: `{len(stats.banned_users)}` | 💎 ویژه: `{len(stats.vip_users)}`\n"
        f"📥 مجموع درخواست‌ها: `{stats.total}` | 🟢 موفق: `{stats.ok}` | 🔴 ناموفق: `{stats.fail}`\n"
        f"💾 کل ترافیک پردازش شده: `{humanize.naturalsize(stats.size)}`\n"
        f"⏱️ آپتایم فعال ربات: `{stats.uptime()}`\n"
        f"🛠️ وضعیت تعمیرات: `{ 'فعال (قفل عمومی)' if stats.maintenance else 'غیرفعال (باز)' }`"
    )
    if message_id:
        try: await ctx.bot.edit_message_text(msg, chat_id=chat_id, message_id=message_id, parse_mode=ParseMode.MARKDOWN, reply_markup=super_giant_admin_keyboard())
        except Exception: pass
    else:
        await ctx.bot.send_message(chat_id, msg, parse_mode=ParseMode.MARKDOWN, reply_markup=super_giant_admin_keyboard())

async def cmd_start(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    u_id = update.effective_user.id
    username = update.effective_user.username
    if str(u_id) in stats.banned_users: return
    stats.add_user(u_id, username)
    lang = stats.get_lang(u_id)
    
    is_joined, unjoined = await check_force_join_status(ctx, u_id)
    if not is_joined:
        channels_text = "\n".join([f"👉 @{ch}" if not (ch.startswith("-100") or ch.isdigit()) else f"👉 ID: {ch}" for ch in unjoined])
        kb = InlineKeyboardMarkup([[InlineKeyboardButton("✅ تایید عضویت / Verify Join ✅", callback_data="check_join")]])
        await update.message.reply_text(
            f"📢 *درود کاربر گرامی!*\n\nجهت استفاده از خدمات پیشرفته ربات، لطفاً ابتدا در کانال‌(های) اسپانسر زیر عضو شده و سپس دکمه تایید را بفشارید:\n\n{channels_text}", 
            parse_mode=ParseMode.MARKDOWN, reply_markup=kb
        )
        return

    welcome_text = config.STRINGS[lang]["welcome"].format(name=update.effective_user.first_name or "User")
    capabilities_text = (
        "\n\n⚙️ *کارایی ربات (Bot Capabilities):*\n"
        "🎬 **FA:** دانلود از یوتیوب، اینستاگرام، تیک‌تاک، توییتر، آپارات، اسپاتیفای، اپل موزیک و لینک‌های مستقیم!\n"
        "🎵 **EN:** Download from YouTube, Instagram, TikTok, Twitter, Spotify, Apple Music & Direct links!"
    )
    
    await update.message.reply_text(welcome_text + capabilities_text, parse_mode=ParseMode.MARKDOWN, reply_markup=main_reply_keyboard(u_id, lang))
    await update.message.reply_text("✨ منوی دسترسی سریع شیشه‌ای / Quick Inline Menu:", reply_markup=main_inline_keyboard(lang))

async def msg_handler(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    u_id = update.effective_user.id
    username = update.effective_user.username
    
    if str(u_id) in stats.banned_users:
        await update.message.reply_text("❌ حساب کاربری شما به دلیل عدم رعایت قوانین سیستم مسدود می‌باشد.")
        return

    if stats.maintenance and u_id not in config.ADMIN_IDS:
        await update.message.reply_text("🛠️ کاربر گرامی، ربات در حال حاضر جهت ارتقای دوره‌ای در دست تعمیر می‌باشد. لطفاً دقایقی دیگر مجدداً تلاش فرمایید.", parse_mode=ParseMode.MARKDOWN)
        return

    is_joined, unjoined = await check_force_join_status(ctx, u_id)
    if not is_joined:
        channels_text = "\n".join([f"👉 @{ch}" if not (ch.startswith("-100") or ch.isdigit()) else f"👉 ID: {ch}" for ch in unjoined])
        kb = InlineKeyboardMarkup([[InlineKeyboardButton("✅ تایید عضویت / Verify Join ✅", callback_data="check_join")]])
        await update.message.reply_text(
            f"📢 *کاربر گرامی!*\n\nجهت فعالسازی سیستم دانلود، لطفا ابتدا در کانال‌های زیر عضو شوید:\n\n{channels_text}\n\nسپس روی دکمه تایید کلیک کنید.", 
            parse_mode=ParseMode.MARKDOWN, reply_markup=kb
        )
        return

    stats.add_user(u_id, username)
    lang = stats.get_lang(u_id)
    s = config.STRINGS[lang]
    text = (update.message.text or "").strip()
    
    action = find_action(text)

    if text in ["انصراف", "❌ انصراف", "برگشت", "بازگشت"] or action == "msg_cancel":
        ctx.user_data["state"] = None
        await update.message.reply_text("🔙 عملیات جاری لغو شد. به منوی اصلی بازگشتید.", reply_markup=main_reply_keyboard(u_id, lang))
        return

    if update.message.reply_to_message and u_id in config.ADMIN_IDS:
        reply_text = update.message.reply_to_message.text or ""
        match = re.search(r"👤 User ID:\s*(\d+)", reply_text)
        if match:
            target_user_id = int(match.group(1))
            try:
                if update.message.text:
                    await ctx.bot.send_message(target_user_id, f"📬 *پاسخ مدیریت سیستم به پیام شما:*\n━━━━━━━━━━━━━━━━━━━━\n{update.message.text}", parse_mode=ParseMode.MARKDOWN)
                else:
                    await ctx.bot.copy_message(target_user_id, from_chat_id=update.message.chat_id, message_id=update.message.message_id)
                await update.message.reply_text("✅ پاسخ شما با موفقیت برای کاربر ارسال گردید.")
            except Exception as e:
                await update.message.reply_text(f"❌ خطا در ارسال پیام به کاربر: {e}")
            return

    state = ctx.user_data.get("state")
    if state and u_id in config.ADMIN_IDS:
        if state == "WAIT_BC_TEXT":
            ctx.user_data["state"] = None
            await update.message.reply_text("⚡ فرآیند ارسال پیام همگانی آغاز شد...")
            ok, fail = 0, 0
            for u in list(stats.users):
                try:
                    await ctx.bot.send_message(int(u), text)
                    ok += 1; await asyncio.sleep(0.04)
                except Exception: fail += 1
            await update.message.reply_text(f"✅ پایان فرآیند! موفق: {ok} | ناموفق: {fail}")
            return

        if state == "WAIT_BC_COPY":
            ctx.user_data["state"] = None
            await update.message.reply_text("⚡ فرآیند هدایت همگانی رسانه آغاز شد...")
            ok, fail = 0, 0
            for u in list(stats.users):
                try:
                    await ctx.bot.copy_message(int(u), from_chat_id=update.message.chat_id, message_id=update.message.message_id)
                    ok += 1; await asyncio.sleep(0.04)
                except Exception: fail += 1
            await update.message.reply_text(f"✅ پایان فرآیند کپی همگانی! موفق: {ok} | ناموفق: {fail}")
            return

        if state in ["WAIT_BAN", "WAIT_UNBAN", "WAIT_VIP_ID", "WAIT_UNVIP", "WAIT_INSPECT"]:
            target_uid = stats.resolve_user_id(text)
            if not target_uid:
                cleaned = text.strip().replace("@", "")
                if cleaned.isdigit(): target_uid = cleaned
                else:
                    await update.message.reply_text("❌ شناسه یا نام کاربری مورد نظر در دیتابیس یافت نشد!")
                    return

            if state == "WAIT_BAN":
                ctx.user_data["state"] = None
                stats.ban(target_uid)
                await update.message.reply_text(f"🎯 کاربر `{target_uid}` با موفقیت مسدود شد.", parse_mode=ParseMode.MARKDOWN)
                return

            if state == "WAIT_UNBAN":
                ctx.user_data["state"] = None
                if stats.unban(target_uid):
                    await update.message.reply_text(f"🟢 کاربر `{target_uid}` رفع مسدودیت شد.", parse_mode=ParseMode.MARKDOWN)
                else:
                    await update.message.reply_text("❌ کاربر در لیست سیاه یافت نشد.")
                return

            if state == "WAIT_VIP_ID":
                ctx.user_data["target_vip_id"] = target_uid
                ctx.user_data["state"] = "WAIT_VIP_LIMIT"
                await update.message.reply_text(f"📦 کاربر شناسایی شد (شناسه: {target_uid}).\nحالا سقف حجم دانلود جدید کاربر را به **مگابایت** وارد کنید (مثال: 1024):", reply_markup=ReplyKeyboardMarkup([[s["msg_cancel"]]], resize_keyboard=True))
                return

            if state == "WAIT_UNVIP":
                ctx.user_data["state"] = None
                if stats.remove_vip(target_uid):
                    await update.message.reply_text(f"💔 کاربر `{target_uid}` از وضعیت VIP حذف شد.")
                else:
                    await update.message.reply_text("❌ کاربر در لیست ویژه یافت نشد.")
                return

            if state == "WAIT_INSPECT":
                ctx.user_data["state"] = None
                is_user = target_uid in stats.users
                is_ban = target_uid in stats.banned_users
                is_vip = target_uid in stats.vip_users
                vip_limit_str = humanize.naturalsize(stats.vip_users[target_uid]) if is_vip else "ندارد"
                u_lang = stats.user_langs.get(target_uid, "نامشخص")
                
                msg = (
                    f"🔍 *نتایج بررسی وضعیت کاربر `{target_uid}`* 🔍\n━━━━━━━━━━━━━━━━━━━━\n"
                    f"👥 سابقه حضور در ربات: {'✅ بله عضو است' if is_user else '❌ خیر'}\n"
                    f"🚫 وضعیت مسدودیت: {'🛑 مسدود' if is_ban else '🟢 آزاد'}\n"
                    f"💎 وضعیت اشتراک: {'👑 ویژه VIP' if is_vip else '⚪ عادی'}\n"
                    f"📦 سقف اختصاصی VIP: `{vip_limit_str}`\n"
                    f"🌐 زبان انتخابی: `{u_lang}`\n━━━━━━━━━━━━━━━━━━━━\n"
                )
                await update.message.reply_text(msg, parse_mode=ParseMode.MARKDOWN)
                return

        if state == "WAIT_VIP_LIMIT":
            ctx.user_data["state"] = None
            try:
                megabytes = int(text.strip())
                limit_bytes = megabytes * 1024 * 1024
                target_uid = ctx.user_data.get("target_vip_id")
                stats.add_vip(target_uid, limit_bytes)
                readable_size = humanize.naturalsize(limit_bytes)
                await update.message.reply_text(f"💎 وضعیت کاربر `{target_uid}` به VIP تغییر یافت و سقف حجم او `{readable_size}` شد.", reply_markup=main_reply_keyboard(u_id, lang))
                try: 
                    await ctx.bot.send_message(int(target_uid), f"💎 *کاربر گرامی، اشتراک شما ارتقا یافت!*\nسقف دانلود شما به **{readable_size}** افزایش یافت.", parse_mode=ParseMode.MARKDOWN)
                except Exception: pass
            except Exception:
                await update.message.reply_text("❌ خطا! لطفاً فقط عدد معتبر بر حسب مگابایت وارد کنید.", reply_markup=main_reply_keyboard(u_id, lang))
            return

        if state == "WAIT_ADD_FJOIN":
            ctx.user_data["state"] = None
            clean_ch = text.replace("@", "").strip()
            if clean_ch not in stats.force_channels:
                stats.force_channels.append(clean_ch)
                stats.save()
                await update.message.reply_text(f"📢 کانال `@{clean_ch}` به لیست قفل‌های اسپانسر اضافه شد.", parse_mode=ParseMode.MARKDOWN)
            else:
                await update.message.reply_text("❌ این کانال از قبل در لیست موجود است.")
            return

        if state == "WAIT_REM_FJOIN":
            ctx.user_data["state"] = None
            clean_ch = text.replace("@", "").strip()
            if clean_ch in stats.force_channels:
                stats.force_channels.remove(clean_ch)
                stats.save()
                await update.message.reply_text(f"✅ کانال `@{clean_ch}` از لیست حذف شد.", parse_mode=ParseMode.MARKDOWN)
            else:
                await update.message.reply_text("❌ کانال مورد نظر یافت نشد.")
            return

        if state == "WAIT_LIMIT":
            ctx.user_data["state"] = None
            try:
                megabytes = int(text)
                stats.normal_limit = megabytes * 1024 * 1024
                stats.save()
                await update.message.reply_text(f"📦 سقف حجم دانلود کاربران عادی روی `{megabytes} مگابایت` تنظیم گردید.")
            except Exception:
                await update.message.reply_text("❌ لطفاً عدد انگلیسی معتبر ارسال فرمایید.")
            return

    if state == "WAITING_FOR_ADMIN_MSG":
        ctx.user_data["state"] = None
        is_vip_user = f"💎 بله" if str(u_id) in stats.vip_users else "⚪ خیر (عادی)"
        for admin_id in config.ADMIN_IDS:
            try:
                await ctx.bot.send_message(admin_id, f"📬 *پیام دریافتی از کاربران:*\n👤 User ID: `{u_id}`\n📛 نام: {update.effective_user.first_name}\n🆔 یوزرنیم: @{update.effective_user.username}\n━━━━━━━━━━━━━━━━━━━━\n💬 متن پیام:\n{text}", parse_mode=ParseMode.MARKDOWN)
            except Exception: pass
        await update.message.reply_text(s["msg_sent_to_admin"], reply_markup=main_reply_keyboard(u_id, lang))
        return

    if action == "btn_stats":
        is_vip_status = f"💎 حساب کاربری ویژه VIP (سقف حجم مجاز: {humanize.naturalsize(stats.vip_users.get(str(u_id), 0))})" if str(u_id) in stats.vip_users else f"⚪ حساب کاربری استاندارد عادی (سقف دانلود: {humanize.naturalsize(stats.normal_limit)})"
        await update.message.reply_text(
            f"📊 *اطلاعات و وضعیت حساب کاربری شما:*\n━━━━━━━━━━━━━━━━━━━━\n"
            f"🆔 *شناسه عددی شما:* `{u_id}`\n"
            f"👤 *نام کاربری شما:* @{username or 'ثبت نشده'}\n"
            f"🎖 *نوع اشتراک:* {is_vip_status}\n━━━━━━━━━━━━━━━━━━━━\n"
            f"👥 اعضای سیستم: `{len(stats.users)}` | VIPها: `{len(stats.vip_users)}`", 
            parse_mode=ParseMode.MARKDOWN
        )
        return
        
    if action == "btn_status":
        cpu = psutil.cpu_percent()
        ram = psutil.virtual_memory().percent
        await update.message.reply_text(f"⚙️ *گزارش وضعیت سخت‌افزاری سرور:*\n━━━━━━━━━━━━━━━━━━━━\n🔥 مصرف پردازنده CPU: `{cpu}%`\n📟 مصرف حافظه RAM: `{ram}%`\n⏱️ آپتایم سرور: `{stats.uptime()}`\n💾 ترافیک کل: {humanize.naturalsize(stats.size)}", parse_mode=ParseMode.MARKDOWN)
        return
    if action == "btn_help":
        await update.message.reply_text(s["help"], parse_mode=ParseMode.MARKDOWN)
        return
    if action == "btn_lang":
        await update.message.reply_text("🌐 لطفا زبان مورد نظر خود را انتخاب فرمایید / Select Language:", reply_markup=lang_keyboard())
        return
    if action == "btn_premium":
        await update.message.reply_text(s["msg_premium_plans"], parse_mode=ParseMode.MARKDOWN)
        return
    if action == "btn_rules":
        await update.message.reply_text(s["msg_rules"], parse_mode=ParseMode.MARKDOWN)
        return
    if action == "btn_contact":
        ctx.user_data["state"] = "WAITING_FOR_ADMIN_MSG"
        await update.message.reply_text(s["msg_ask_admin"], reply_markup=ReplyKeyboardMarkup([[s["msg_cancel"]]], resize_keyboard=True))
        return
    if action == "btn_admin" and u_id in config.ADMIN_IDS:
        await send_admin_panel(update.message.chat_id, ctx)
        return

    if not dl.is_url(text):
        await update.message.reply_text("🔗 کاربر گرامی، لطفاً یک لینک اینترنتی معتبر جهت استخراج و دانلود ارسال فرمایید.")
        return
    
    platform = dl.detect_platform(text)
    ctx.user_data["url"] = text
    wait = await update.message.reply_text(f"{s['msg_analyzing']}\n🌐 پلتفرم منبع: {platform}", parse_mode=ParseMode.MARKDOWN)
    
    is_file, filename, ext = await dl.check_direct_file(text)
    if is_file and ext not in ['.html', '.htm', '']:
        await wait.edit_text(s["msg_direct_file"], parse_mode=ParseMode.MARKDOWN)
        await run_file_download(wait, ctx, text, update.message.chat_id, lang, u_id)
        return

    info = await asyncio.get_event_loop().run_in_executor(None, dl.get_info, text)
    if info:
        ctx.user_data["media_info"] = info  
        caption = dl.format_info(info, lang)
        await wait.edit_text(caption, parse_mode=ParseMode.MARKDOWN, reply_markup=quality_keyboard(lang))
    else:
        if is_file:
            await wait.edit_text(s["msg_direct_file"], parse_mode=ParseMode.MARKDOWN)
            await run_file_download(wait, ctx, text, update.message.chat_id, lang, u_id)
        else:
            stats.failure(); await wait.delete()
            await ctx.bot.send_message(update.message.chat_id, s["msg_err_generic"])

async def run_file_download(wait_msg, ctx, url: str, chat_id: int, lang: str, user_id: int):
    s = config.STRINGS[lang]
    file_info = await asyncio.get_event_loop().run_in_executor(None, lambda: dl.download_generic_file(url))
    if not file_info:
        stats.failure(); await wait_msg.delete()
        await ctx.bot.send_message(chat_id, s["msg_err_generic"])
        return
        
    file_path, filename = file_info
    size = os.path.getsize(file_path)
    
    allowed_limit = stats.vip_users.get(str(user_id), stats.normal_limit)
    if size > allowed_limit:
        stats.failure(); dl.cleanup(file_path); await wait_msg.delete()
        readable_limit = humanize.naturalsize(allowed_limit)
        await ctx.bot.send_message(chat_id, s["msg_err_size"].format(limit=readable_limit), parse_mode=ParseMode.MARKDOWN)
        return
        
    if filename.lower().endswith('.mp4'):
        file_path = await asyncio.get_event_loop().run_in_executor(None, lambda: dl.ensure_faststart(file_path))

    await wait_msg.edit_text(f"{s['msg_uploading']}\n📦 حجم فایل: {humanize.naturalsize(size)}", parse_mode=ParseMode.MARKDOWN)
    
    try:
        is_pic = any(filename.lower().endswith(ext) for ext in ['.jpg', '.jpeg', '.png', '.webp', '.wpeg'])
        if_vid = any(filename.lower().endswith(ext) for ext in ['.mp4', '.mkv', '.mov', '.avi'])
        if_aud = any(filename.lower().endswith(ext) for ext in ['.mp3', '.m4a', '.ogg', '.wav'])
        
        info = ctx.user_data.get("media_info") or {}
        duration = int(info.get("duration")) if info.get("duration") else None
        width = int(info.get("width")) if info.get("width") else None
        height = int(info.get("height")) if info.get("height") else None

        with open(file_path, "rb") as f:
            if is_pic:
                await ctx.bot.send_photo(chat_id, photo=f, caption=s["msg_success"], parse_mode=ParseMode.MARKDOWN)
            elif if_vid:
                await ctx.bot.send_video(chat_id, video=f, caption=s["msg_success"], parse_mode=ParseMode.MARKDOWN, supports_streaming=True, duration=duration, width=width, height=height, read_timeout=600, write_timeout=600)
            elif if_aud:
                await ctx.bot.send_audio(chat_id, audio=f, caption=s["msg_success"], parse_mode=ParseMode.MARKDOWN)
            else:
                await ctx.bot.send_document(chat_id, document=f, filename=filename, caption=s["msg_success"], parse_mode=ParseMode.MARKDOWN)
        stats.success(size); await wait_msg.delete()
    except Exception as e:
        stats.failure(); await ctx.bot.send_message(chat_id, f"❌ خطا در ارسال فایل: {e}")
    finally: 
        dl.cleanup(file_path) 

async def cb_handler(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    q = update.callback_query
    chat = q.message.chat_id
    u_id = update.effective_user.id
    lang = stats.get_lang(u_id)
    s = config.STRINGS[lang]
    await q.answer()
    
    if q.data == "cancel" or q.data == "admin:close": 
        await q.message.delete(); return

    if q.data == "check_join":
        is_joined, unjoined = await check_force_join_status(ctx, u_id)
        if is_joined:
            await q.message.delete()
            welcome_text = config.STRINGS[lang]["welcome"].format(name=update.effective_user.first_name or "User")
            capabilities_text = (
                "\n\n⚙️ *کارایی ربات (Bot Capabilities):*\n"
                "🎬 **FA:** دانلود از یوتیوب، اینستاگرام، تیک‌تاک، توییتر، آپارات، اسپاتیفای، اپل موزیک و لینک‌های مستقیم!\n"
                "🎵 **EN:** Download from YouTube, Instagram, TikTok, Twitter, Spotify, Apple Music & Direct links!"
            )
            await ctx.bot.send_message(chat, welcome_text + capabilities_text, parse_mode=ParseMode.MARKDOWN, reply_markup=main_reply_keyboard(u_id, lang))
            await ctx.bot.send_message(chat, "✨ منوی دسترسی سریع شیشه‌ای / Quick Inline Menu:", reply_markup=main_inline_keyboard(lang))
        else:
            await q.answer("❌ شما هنوز در تمام کانال‌های اسپانسر عضو نشده‌اید!", show_alert=True)
        return

    if q.data.startswith("menu:"):
        action = q.data.split(":")[1]
        if action == "stats":
            is_vip_status = f"💎 حساب VIP" if str(u_id) in stats.vip_users else f"⚪ حساب عادی"
            await ctx.bot.send_message(chat, f"📊 *وضعیت حساب شما:*\n🆔 شناسه: `{u_id}`\n🎖 نوع اشتراک: {is_vip_status}", parse_mode=ParseMode.MARKDOWN)
        elif action == "status":
            cpu = psutil.cpu_percent()
            ram = psutil.virtual_memory().percent
            await ctx.bot.send_message(chat, f"⚙️ *وضعیت سخت‌افزار:* CPU: `{cpu}%` | RAM: `{ram}%`", parse_mode=ParseMode.MARKDOWN)
        elif action == "premium":
            await ctx.bot.send_message(chat, s["msg_premium_plans"], parse_mode=ParseMode.MARKDOWN)
        elif action == "help":
            await ctx.bot.send_message(chat, s["help"], parse_mode=ParseMode.MARKDOWN)
        elif action == "rules":
            await ctx.bot.send_message(chat, s["msg_rules"], parse_mode=ParseMode.MARKDOWN)
        return

    if q.data == "btn_lang_inline":
        await ctx.bot.send_message(chat, "🌐 Change Language / تغییر زبان:", reply_markup=lang_keyboard())
        return
    
    if q.data == "adm:manage_fj":
        list_ch = "\n".join([f"🔹 @{c}" for c in stats.force_channels]) if stats.force_channels else "هیچ کانالی تنظیم نشده است."
        text = f"📢 *بخش مدیریت یکپارچه کانال‌های اسپانسر*\n\nکانال‌های فعلی:\n{list_ch}\n\nیک اقدام را انتخاب کنید:"
        kb = InlineKeyboardMarkup([
            [InlineKeyboardButton("➕ افزودن کانال", callback_data="adm:add_fj"), InlineKeyboardButton("➖ حذف کانال خاص", callback_data="adm:rem_fj_single")],
            [InlineKeyboardButton("🗑️ حذف کل کانال‌ها", callback_data="adm:clear_fj")],
            [InlineKeyboardButton("🔙 بازگشت به پنل", callback_data="adm:back_to_admin")]
        ])
        await q.message.edit_text(text, parse_mode=ParseMode.MARKDOWN, reply_markup=kb)
        return

    if q.data == "adm:back_to_admin":
        await send_admin_panel(chat, ctx, message_id=q.message.message_id)
        return

    if q.data.startswith("adm:") and u_id in config.ADMIN_IDS:
        action = q.data.split(":")[1]
        cancel_kb = ReplyKeyboardMarkup([[s["msg_cancel"]]], resize_keyboard=True)
        
        if action == "bc_text":
            ctx.user_data["state"] = "WAIT_BC_TEXT"
            await ctx.bot.send_message(chat, "📝 متن ارسالی خود را وارد نمایید:", reply_markup=cancel_kb)
        elif action == "bc_copy":
            ctx.user_data["state"] = "WAIT_BC_COPY"
            await ctx.bot.send_message(chat, "🔄 رسانه، عکس یا بنر هدف را جهت کپی همگانی ارسال کنید:", reply_markup=cancel_kb)
        elif action == "ban":
            ctx.user_data["state"] = "WAIT_BAN"
            await ctx.bot.send_message(chat, "🚫 آیدی عددی یا یوزرنیم کاربر را بدون @ جهت مسدودسازی ارسال کنید:", reply_markup=cancel_kb)
        elif action == "unban":
            ctx.user_data["state"] = "WAIT_UNBAN"
            await ctx.bot.send_message(chat, "🟢 آیدی عددی یا یوزرنیم کاربر را جهت رفع مسدودیت ارسال کنید:", reply_markup=cancel_kb)
        elif action == "add_vip":
            ctx.user_data["state"] = "WAIT_VIP_ID"
            await ctx.bot.send_message(chat, "💎 آیدی عددی یا یوزرنیم کاربر را جهت ارتقا به VIP ارسال کنید:", reply_markup=cancel_kb)
        elif action == "rem_vip":
            ctx.user_data["state"] = "WAIT_UNVIP"
            await ctx.bot.send_message(chat, "💔 آیدی عددی یا یوزرنیم کاربر را جهت عزل از وضعیت VIP ارسال کنید:", reply_markup=cancel_kb)
        elif action == "inspect_user":
            ctx.user_data["state"] = "WAIT_INSPECT"
            await ctx.bot.send_message(chat, "🔍 آیدی عددی یا یوزرنیم کاربر را جهت بررسی کامل دیتابیس ارسال کنید:", reply_markup=cancel_kb)
        elif action == "add_fj":
            ctx.user_data["state"] = "WAIT_ADD_FJOIN"
            await ctx.bot.send_message(chat, "📢 آیدی کانال اسپانسر جدید را بدون @ ارسال کنید (مثال: myChannel):", reply_markup=cancel_kb)
        elif action == "rem_fj_single":
            ctx.user_data["state"] = "WAIT_REM_FJOIN"
            await ctx.bot.send_message(chat, "📢 آیدی کانال اسپانسر مورد نظر جهت حذف را بدون @ ارسال کنید:", reply_markup=cancel_kb)
        elif action == "clear_fj":
            stats.force_channels = []
            stats.save()
            await q.message.edit_text("⚙️ *تمامی قفل‌های کانال اسپانسر حذف گردیدند.*", parse_mode=ParseMode.MARKDOWN, reply_markup=super_giant_admin_keyboard())
        elif action == "set_lim":
            ctx.user_data["state"] = "WAIT_LIMIT"
            await ctx.bot.send_message(chat, "📦 سقف دانلود کاربران عادی را به مگابایت وارد کنید:", reply_markup=cancel_kb)
        elif action == "reset_all":
            stats.reset()
            await q.message.edit_text("⚙️ *کل آمار و دیتابیس ربات ریست گردید.*", parse_mode=ParseMode.MARKDOWN, reply_markup=super_giant_admin_keyboard())
        elif action == "toggle_maint":
            stats.maintenance = not stats.maintenance
            stats.save()
            await send_admin_panel(chat, ctx, message_id=q.message.message_id)
        elif action == "get_db":
            if os.path.exists(stats.file_path):
                await ctx.bot.send_document(chat, document=open(stats.file_path, "rb"), filename="bot_database_backup.json", caption="📁 دیتابیس کامل کاربران.")
            else:
                await ctx.bot.send_message(chat, "❌ دیتابیس یافت نشد.")
        elif action == "clean":
            count = 0
            freed_size = 0
            dl_dir = Path(config.DOWNLOAD_PATH)
            if dl_dir.exists():
                for f in dl_dir.iterdir():
                    try:
                        if f.is_file():
                            f_size = f.stat().st_size
                            os.remove(f)
                            count += 1
                            freed_size += f_size
                    except Exception: pass
            
            readable_freed = humanize.naturalsize(freed_size)
            await ctx.bot.send_message(chat, f"🧹 *عملیات پاکسازی هارد با موفقیت انجام شد!*\n\n🔹 تعداد `{count}` فایل زائد از پوشه دانلود کاربران با موفقیت حذف گردید.\n📥 مقدار فضای آزاد شده روی دیسک سرور: `{readable_freed}`", parse_mode=ParseMode.MARKDOWN)
            await send_admin_panel(chat, ctx, message_id=q.message.message_id)
        return

    if q.data.startswith("lang:"):
        nl = q.data.split(":")[1]
        stats.set_lang(u_id, nl)
        await q.message.delete()
        welcome_text = config.STRINGS[nl]["welcome"].format(name=update.effective_user.first_name or "User")
        await ctx.bot.send_message(chat, welcome_text, parse_mode=ParseMode.MARKDOWN, reply_markup=main_reply_keyboard(u_id, nl))
        return
        
    if q.data.startswith("q:"):
        quality = q.data.split(":")[1]
        url     = ctx.user_data.get("url")
        if not url: await q.message.reply_text("❌ لینک در حافظه موقت سرور یافت نشد!"); return
        await run_video_download(q, ctx, url, quality, chat, lang, u_id)

async def run_video_download(q, ctx, url: str, quality: str, chat_id: int, lang: str, user_id: int):
    s = config.STRINGS[lang]
    label_key = f"label_{lang}" if f"label_{lang}" in config.VIDEO_QUALITIES[quality] else "label_fa"
    q_label = config.VIDEO_QUALITIES[quality].get(label_key, config.VIDEO_QUALITIES[quality]["label_fa"])
    is_audio, is_photo = quality in ["mp3", "m4a"], quality == "photo"
    
    try: await q.message.edit_text(f"{s['msg_downloading']}\n🎛️ فرمت: {q_label}", parse_mode=ParseMode.MARKDOWN)
    except Exception: pass
    
    file_path, err = None, None
    try: file_path = await asyncio.get_event_loop().run_in_executor(None, lambda: dl.download(url, quality))
    except Exception as e: err = str(e)
    
    if err or not file_path:
        stats.failure(); await ctx.bot.send_message(chat_id, s["msg_err_generic"])
        return
        
    size = os.path.getsize(file_path)
    allowed_limit = stats.vip_users.get(str(user_id), stats.normal_limit)
    if size > allowed_limit:
        stats.failure(); dl.cleanup(file_path); await q.message.delete()
        readable_limit = humanize.naturalsize(allowed_limit)
        await ctx.bot.send_message(chat_id, s["msg_err_size"].format(limit=readable_limit), parse_mode=ParseMode.MARKDOWN)
        return
        
    await q.message.edit_text(f"{s['msg_uploading']}\n📦 حجم رسانه: {humanize.naturalsize(size)}", parse_mode=ParseMode.MARKDOWN)
    await ctx.bot.send_chat_action(chat_id, ChatAction.UPLOAD_VOICE if is_audio else (ChatAction.UPLOAD_PHOTO if is_photo else ChatAction.UPLOAD_VIDEO))
    
    try:
        info = ctx.user_data.get("media_info") or {}
        duration = int(info.get("duration")) if info.get("duration") else None
        width = int(info.get("width")) if info.get("width") else None
        height = int(info.get("height")) if info.get("height") else None

        with open(file_path, "rb") as f:
            if is_photo: 
                await ctx.bot.send_photo(chat_id, photo=f, caption=s["msg_success"], parse_mode=ParseMode.MARKDOWN)
            elif is_audio: 
                await ctx.bot.send_audio(chat_id, audio=f, caption=s["msg_success"], parse_mode=ParseMode.MARKDOWN)
            else: 
                await ctx.bot.send_video(chat_id, video=f, caption=s["msg_success"], parse_mode=ParseMode.MARKDOWN, supports_streaming=True, duration=duration, width=width, height=height, read_timeout=600, write_timeout=600)
        
        stats.success(size); await q.message.delete()
    except Exception as e:
        stats.failure(); await ctx.bot.send_message(chat_id, f"❌ خطا در آپلود نهایی فایل: {e}")
    finally: 
        dl.cleanup(file_path) 

def main():
    console.print(Panel("🎬 [bold cyan]Universal Downloader Bot (PRO QUAD-LANG V6)[/bold cyan]", border_style="cyan"))
    app = Application.builder().token(config.BOT_TOKEN).base_url("http://localhost:8081/bot").local_mode(True).read_timeout(600).write_timeout(600).build()
    app.add_handler(CommandHandler("start", cmd_start))
    app.add_handler(CallbackQueryHandler(cb_handler))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, msg_handler))
    app.add_handler(MessageHandler(filters.ALL & ~filters.COMMAND, msg_handler))
    app.run_polling(allowed_updates=Update.ALL_TYPES, drop_pending_updates=True)

if __name__ == "__main__": main()
PYEOF
echo -e "${G}✅ bot.py با ساختار جدید با موفقیت بازنویسی شد${N}"

# ════════════════════════════════════════════════════════════
#  ساخت requirements.txt همراه با psutil جهت آنالیز سخت‌افزار
# ════════════════════════════════════════════════════════════
cat > requirements.txt << 'EOF'
python-telegram-bot==20.7
yt-dlp
python-dotenv
humanize
rich
httpx
psutil
EOF

# ════════════════════════════════════════════════════════════
#  ساخت run.sh
# ════════════════════════════════════════════════════════════
cat > run.sh << 'RUNEOF'
#!/bin/bash
cd "$HOME/downloader-bot" || exit 1
docker start telegram-bot-api &> /dev/null
pip install -q --upgrade yt-dlp
python3 bot.py
RUNEOF
chmod +x run.sh

# ════════════════════════════════════════════════════════════
#  نصب پکیج‌ها
# ════════════════════════════════════════════════════════════
echo -e "\n${Y}📦 در حال نصب پکیج‌های جدید و فعال‌سازی موتور مانیتورینگ سرور...${N}"
pip install -q -r requirements.txt
pip install -q --upgrade yt-dlp
echo -e "${G}✅ همه پکیج‌های پیشرفته نصب شدند.${N}"

echo -e "\n${G}🚀 سوپر ربات با موفقیت آپدیت شد! با دستور زیر روشن کن رئیس:${N}"
echo -e "${C}python3 bot.py${N}\n"


توکن ربات که باید اناده در کد قرار بدی :
8525496066:AAHfkEhChRG76u3GK7pwTYxBzCG28ebbvSw

ایدی عددی ادمین که باید قرار بدی :
1033630752


یادت نره محدودیت ۲ گیگ تلگرامم داشته باشه .
