---
description: Deploy Backend to Render (Free Hosting)
---

# Deploy FareFinder Backend to Render

This guide will help you deploy your Node.js backend to Render so your app works anywhere without manually starting the backend.

## Prerequisites

- GitHub account
- Render account (free) - Sign up at https://render.com
- Your Google Maps API key

## Step 1: Push Your Code to GitHub

Make sure your backend code is pushed to GitHub:

```bash
git add .
git commit -m "Prepare backend for deployment"
git push origin main
```

## Step 2: Create a Render Account

1. Go to https://render.com
2. Click "Get Started for Free"
3. Sign up with your GitHub account

## Step 3: Create a New Web Service

1. Click "New +" button in the Render dashboard
2. Select "Web Service"
3. Connect your GitHub repository
4. Select the repository: `Fare-Finder-Cabs-and-Bikes`

## Step 4: Configure the Service

Fill in the following details:

- **Name**: `farefinder-backend` (or any name you prefer)
- **Region**: Choose the closest to your users (e.g., Singapore for India)
- **Branch**: `main`
- **Root Directory**: `backend`
- **Runtime**: `Node`
- **Build Command**: `npm install`
- **Start Command**: `npm start`
- **Instance Type**: `Free`

## Step 5: Add Environment Variables

In the "Environment" section, click "Add Environment Variable" and add:

- **Key**: `GOOGLE_MAPS_API_KEY`
- **Value**: Your actual Google Maps API key

## Step 6: Deploy

1. Click "Create Web Service"
2. Render will automatically build and deploy your backend
3. Wait for the deployment to complete (usually 2-3 minutes)
4. You'll get a URL like: `https://farefinder-backend.onrender.com`

## Step 7: Update Your Flutter App

1. Open your `.env` file in the root of your Flutter project
2. Add the backend URL:
   ```
   BACKEND_URL=https://farefinder-backend.onrender.com/api
   ```
   (Replace with your actual Render URL)

3. Save the file

## Step 8: Test Your Deployment

Test your backend is working:

1. Open your browser and go to: `https://your-backend-url.onrender.com/api/health`
2. You should see: `{"status":"OK","mode":"REAL"}`

## Step 9: Run Your Flutter App

```bash
flutter run
```

Your app will now use the hosted backend!

## Important Notes

### Free Tier Limitations

- **Sleep after 15 minutes**: The free tier sleeps after 15 minutes of inactivity
- **Wake-up time**: Takes ~30 seconds to wake up on first request
- **Solution**: Upgrade to paid tier ($7/month) for always-on service, or use a service like UptimeRobot to ping your backend every 10 minutes

### Auto-Deploy on Git Push

Render automatically redeploys when you push to GitHub:

```bash
# Make changes to backend
cd backend
# Edit files...

# Commit and push
git add .
git commit -m "Update backend"
git push origin main

# Render will automatically deploy the changes!
```

### Monitoring

- View logs in the Render dashboard under "Logs" tab
- Monitor performance and uptime
- Get email alerts for deployment failures

## Alternative: Keep Backend Awake (Free)

To prevent the free tier from sleeping, use a free service like **UptimeRobot**:

1. Sign up at https://uptimerobot.com (free)
2. Create a new monitor:
   - Monitor Type: HTTP(s)
   - URL: `https://your-backend-url.onrender.com/api/health`
   - Monitoring Interval: 5 minutes
3. This will ping your backend every 5 minutes, keeping it awake

## Troubleshooting

### Backend not responding
- Check Render logs for errors
- Verify environment variables are set correctly
- Ensure Google Maps API key is valid

### Flutter app can't connect
- Verify BACKEND_URL in `.env` file
- Make sure URL includes `/api` at the end
- Check that you've run `flutter pub get` after updating `.env`

### Build failures
- Check that `package.json` is in the `backend` directory
- Verify all dependencies are listed in `package.json`
- Check Render build logs for specific errors

## Cost Breakdown

### Free Tier (Render)
- ✅ 750 hours/month (enough for 1 service)
- ✅ Automatic HTTPS
- ✅ Auto-deploy from GitHub
- ⚠️ Sleeps after 15 min inactivity

### Paid Tier ($7/month)
- ✅ Always-on (no sleep)
- ✅ More resources
- ✅ Better performance

## Next Steps

Once deployed, you can:

1. **Submit to Play Store**: Your app now has a production backend
2. **Monitor usage**: Track API calls and performance
3. **Scale up**: Upgrade to paid tier when needed
4. **Add features**: Deploy updates automatically via git push

---

**Congratulations! Your backend is now hosted and accessible from anywhere! 🎉**
