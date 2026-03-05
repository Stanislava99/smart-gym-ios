# Smart Gym - iOS Member App

Member-facing mobile app for Smart Gym, built with SwiftUI and MVVM.

## Architecture

- **MVVM** – ViewModels with `@Observable`, Views observe state
- **Supabase** – Auth, PostgREST (shared project with gym-companion)
- **Navigation** – TabView (Home, Favorites, Profile)

## Project Structure

```
SmartGym/
├── Data/
│   ├── Remote/          # SupabaseClient (AppSupabase)
│   └── Repositories/    # AuthRepository, MemberRepository
├── Domain/
│   └── Models/          # Member
├── Presentation/
│   ├── Auth/            # AuthViewModel, LoginView
│   ├── Home/            # HomeViewModel, HomeView
│   ├── Profile/         # ProfileViewModel, ProfileView
│   └── Navigation/      # AppNavigationView
└── SmartGymApp.swift
```

## Supabase Setup

1. Get your **anon key** from [Supabase Dashboard](https://supabase.com/dashboard) → Project Settings → API.
2. Set the environment variable or update `AppSupabase` in `Data/Remote/SupabaseClient.swift`:
   ```swift
   let key = "your_anon_key_here"
   ```
3. For release builds, use a secure config (e.g. xcconfig, not committed).

The app uses the same Supabase project as gym-companion (`ywpxdolvmrobczzyyfgt`).

## Member Account Linking

Members must have their gym account linked to a Supabase Auth user. Staff do this from the gym-companion web app via "Send member invite" or "Link account".
