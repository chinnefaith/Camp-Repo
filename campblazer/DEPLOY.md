# Deploying CampBlazer for free

| Option | What it gives you | Cost | Best for |
|---|---|---|---|
| A. GitHub | Your code online, version history, shareable repo link | Free | Submitting / sharing the source |
| B. Laptop + Cloudflare Quick Tunnel | A public `https://….trycloudflare.com` link to the app running on YOUR laptop: 4 workers, PostgreSQL, Redis, live WebSockets | Free, no account | The panel demo (full PDC features) |
| D. GitHub Codespaces | The whole app (backend + frontend + PostgreSQL + Redis) runs in GitHub's cloud; a public `…app.github.dev` link | Free monthly hours on a personal account | Deploying from GitHub without your laptop running it |
| C. Render + Neon | Always-reachable website, no laptop needed | Free tiers (sleeps when idle; can hit account limits) | Leaving it online after the defense |

---

## A. Put the code on GitHub

1. Create an empty repository on github.com (New → name it `campblazer` → **don't** add a README).
2. In the VS Code terminal, inside the `campblazer` folder:

```bash
git init
git add .
git commit -m "CampBlazer capstone"
git branch -M main
git remote add origin https://github.com/<your-username>/campblazer.git
git push -u origin main
```

`.gitignore` already keeps out `.env` (secrets), `.venv`, `node_modules`, uploaded media and test results.
Check with `git status` before committing: **`.env` must never appear**. If it does, stop and run `git rm --cached backend/.env`.

GitHub stores the code only; it doesn't run Django. Use B or C to run it.

---

## B. Laptop as the server + Cloudflare Quick Tunnel (recommended for the demo)

Everything runs on your laptop exactly as in the setup guide; Cloudflare gives it a temporary public HTTPS link.

1. Install `cloudflared`. On Windows: `winget install --id Cloudflare.cloudflared`, then reopen VS Code.
2. In `backend/.env` set:

```
DJANGO_DEBUG=False
DJANGO_ALLOWED_HOSTS=127.0.0.1,localhost,.trycloudflare.com
SERVE_MEDIA=1
```

   (DEBUG off so visitors never see error pages with your settings; `SERVE_MEDIA=1` keeps the photos working.)
3. Start PostgreSQL + Redis and the backend as usual:

```powershell
docker compose up -d
cd backend; .venv\Scripts\activate
python run_server_windows.py --workers 4
```

4. Build and serve the frontend (new terminal):

```powershell
cd frontend
npm run build
npm run preview          # http://localhost:4173 — proxies /api, /media and /ws to Django
```

**Shortcut:** after the one-time setup, `powershell -ExecutionPolicy Bypass -File .\start-public.ps1` (in the `campblazer` folder) does steps 3–5 for you in separate windows.

5. Open the tunnel (new terminal):

```powershell
cloudflared tunnel --url http://localhost:4173
```

   It prints a link like `https://random-words.trycloudflare.com`. Anyone can open it on their phone or laptop. Bookings, approvals and live updates all work through it.

Notes:
- The link changes every time you restart `cloudflared`, and it stops when you press Ctrl + C or the laptop sleeps.
- Keep the laptop plugged in and set sleep to "Never" during the demo.
- Quick Tunnels are meant for testing and demos, not permanent hosting.

---

## C. Always online: Render (backend + frontend + Redis) + Neon (PostgreSQL)

`render.yaml` in the project root sets everything up from your GitHub repo (do A first).

1. **Neon** (neon.com) → sign up free → create a project → copy the **direct** connection string (`postgresql://…?sslmode=require`).
2. **Render** (render.com) → sign up with GitHub → **New → Blueprint** → pick the `campblazer` repo.
3. Render asks for the values marked `sync: false`. Use the addresses Render shows for your two services:

| Service | Variable | Value |
|---|---|---|
| campblazer-api | `DATABASE_URL` | the Neon connection string |
| campblazer-api | `CORS_ALLOWED_ORIGINS` | `https://campblazer.onrender.com` (your frontend address) |
| campblazer-api | `CSRF_TRUSTED_ORIGINS` | `https://campblazer-api.onrender.com` (your API address) |
| campblazer-api | `PHOTO_BASE_URL` | the frontend address again |
| campblazer | `VITE_API_URL` | the API address |

4. Deploy. The start script runs migrations and loads the 18 destinations, photos and demo accounts. The demo password is in the API service's **Environment** tab (`DEMO_PASSWORD`).

Free-tier limits to know before the defense:
- The free web service **sleeps after 15 minutes without traffic** and takes about a minute to wake. Open the site a few minutes before presenting.
- It runs on a small shared CPU (2 workers), so do the **speedup / load tests on your laptop**, not on Render.
- Uploaded files are wiped on restart. The 18 seeded photos are safe because the frontend serves them.
- Render's own free PostgreSQL expires after 30 days, which is why this setup uses Neon instead.

---

## D. Run it on GitHub Codespaces (from your GitHub repo, no laptop needed while it runs)

GitHub Pages can't run Django (static files only), but **Codespaces** gives you a free Linux machine in GitHub's cloud that can run everything.

1. Do **A** first (code on GitHub).
2. On the repo page: **Code → Codespaces → Create codespace on main** (2-core machine). VS Code opens in the browser.
3. In its terminal:

```bash
docker compose up -d                       # PostgreSQL + Redis inside the codespace
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
```

4. Edit `backend/.env`: paste a secret key, and set
   `DJANGO_ALLOWED_HOSTS=127.0.0.1,localhost,.app.github.dev` and `SERVE_MEDIA=1`, `DJANGO_DEBUG=False`.
5. Load the data and start 4 workers:

```bash
python manage.py makemigrations accounts destinations bookings && python manage.py migrate
python manage.py seed_destinations && python manage.py seed_photos --reset && python manage.py seed_demo
gunicorn -c gunicorn.conf.py config.asgi:application
```

6. New terminal: `cd frontend && npm install && npm run build && npm run preview`
7. Open the **Ports** tab → port **4173** → right-click → **Port Visibility → Public**. Copy its `https://…-4173.app.github.dev` link and share it.

Notes:
- Free personal accounts get a monthly allowance of Codespaces core-hours. A 2-core codespace uses 2 core-hours per hour, so **stop the codespace when you're done** (Codespaces page → ⋯ → Stop).
- A codespace stops itself after a period of inactivity, and the link stops working then. Restart it and re-run steps 5–7 (the database is kept).
