"use server"

import { cookies } from "next/headers"
import { revalidatePath } from "next/cache"
import { IS_PRODUCTION } from "@/constants/constants"

export type Theme = "dark" | "light" | "system"

const THEME_COOKIE_NAME = "smicrab-ui-theme"
const THEME_COOKIE_MAX_AGE = 60 * 60 * 24 * 365 // 1 year

export async function getTheme(): Promise<Theme> {
  const cookieStore = await cookies()
  const theme = cookieStore.get(THEME_COOKIE_NAME)?.value as Theme
  return theme || "system"
}

export async function setTheme(theme: Theme) {
  const cookieStore = await cookies()
  
  cookieStore.set(THEME_COOKIE_NAME, theme, {
    maxAge: THEME_COOKIE_MAX_AGE,
    httpOnly: false, // Allow client-side access for theme script
    secure: IS_PRODUCTION,
    sameSite: "lax",
    path: "/",
  })

  // Revalidate the current path to update the theme
  revalidatePath("/", "layout")
}

export async function getResolvedTheme(): Promise<"dark" | "light"> {
  const theme = await getTheme()
  
  if (theme === "system") {
    // On server side, we default to light for system theme
    // The client-side script will handle the actual system preference
    return "light"
  }
  
  return theme
} 