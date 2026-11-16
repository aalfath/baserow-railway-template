"""Create Baserow's first (staff) user from the environment and close public sign-up.

Runs once per boot, before Baserow listens. It only acts while the database has no
users, so a password changed in Baserow is never overwritten, and sign-up stays the
way the admin later sets it in Admin > Settings.
"""
import os
import sys

import django

django.setup()

from django.contrib.auth import get_user_model  # noqa: E402
from django.db import transaction  # noqa: E402

from baserow.core.models import Settings  # noqa: E402
from baserow.core.user.handler import UserHandler  # noqa: E402

User = get_user_model()


def save_settings(**fields):
    # Load the row fresh and save() it: a settings object loaded before create_user()
    # would write back a stale show_admin_signup_page=True, and save() (unlike
    # QuerySet.update) fires the post_save receiver that clears Baserow's Redis cache.
    settings = Settings.objects.first()
    if settings is None:
        settings = Settings()
    changed = [k for k, v in fields.items() if getattr(settings, k) != v]
    for k in changed:
        setattr(settings, k, fields[k])
    if changed or settings.pk is None:
        settings.save()


if User.objects.exists():
    # Baserow clears this flag when its first user is created; make sure no earlier
    # boot left it on, or /login would redirect to the "create admin" page.
    save_settings(show_admin_signup_page=False)
    print("[railway] Users already exist; leaving accounts and sign-up settings alone.")
    sys.exit(0)

email = os.environ.get("BASEROW_ADMIN_EMAIL", "").strip().lower()
password = os.environ.get("BASEROW_ADMIN_PASSWORD", "")
if "@" not in email or len(password) < 8:
    sys.exit(
        "[railway] Refusing to start: the database has no users, and "
        "BASEROW_ADMIN_EMAIL (an email address) and BASEROW_ADMIN_PASSWORD "
        "(8+ characters) must both be set. Without them, the first visitor to this "
        "URL would become Baserow's admin."
    )

with transaction.atomic():
    user = UserHandler().create_user(
        name=email.split("@")[0], email=email, password=password, email_verified=True
    )
    save_settings(allow_new_signups=False, show_admin_signup_page=False)

print(
    f"[railway] Created admin {user.email} (staff={user.is_staff}) "
    "and turned public sign-up off."
)
