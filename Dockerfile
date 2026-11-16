# Baserow all-in-one, pinned by version and digest. Bump both together and add a
# CHANGELOG.md entry: a merge to main notifies everyone who deployed the template.
FROM baserow/baserow:2.4.3@sha256:304bebe22bf4c66d96d11bb746727492fa91637bd6deb807b2ef464f071c215c

COPY railway/ /baserow-railway/
RUN chmod 755 /baserow-railway/start.sh && chmod 644 /baserow-railway/seed_admin.py

# The wrapper migrates the database and creates the admin before Baserow listens.
ENTRYPOINT ["/baserow-railway/start.sh"]
CMD []
