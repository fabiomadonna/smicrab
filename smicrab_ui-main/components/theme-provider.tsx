"use client"

import * as React from "react"
import { createContext, useContext, useEffect, useState, useTransition } from "react"
import { setTheme as setThemeAction, type Theme } from "@/lib/theme-actions"

type ThemeProviderProps = {
  children: React.ReactNode
  defaultTheme: Theme
}

type ThemeProviderState = {
  theme: Theme
  setTheme: (theme: Theme) => Promise<void>
  isUpdating: boolean
}

const initialState: ThemeProviderState = {
  theme: "system",
  setTheme: async () => {},
  isUpdating: false,
}

const ThemeProviderContext = createContext<ThemeProviderState>(initialState)

export function ThemeProvider({
  children,
  defaultTheme,
  ...props
}: ThemeProviderProps) {
  const [theme, setThemeState] = useState<Theme>(defaultTheme)
  const [isPending, startTransition] = useTransition()

  useEffect(() => {
    const root = window.document.documentElement

    root.classList.remove("light", "dark")

    if (theme === "system") {
      const systemTheme = window.matchMedia("(prefers-color-scheme: dark)")
        .matches
        ? "dark"
        : "light"

      root.classList.add(systemTheme)
      return
    }

    root.classList.add(theme)
  }, [theme])

  // Listen for system theme changes when theme is set to "system"
  useEffect(() => {
    if (theme !== "system") return

    const mediaQuery = window.matchMedia("(prefers-color-scheme: dark)")
    const handleChange = () => {
      const root = window.document.documentElement
      root.classList.remove("light", "dark")
      root.classList.add(mediaQuery.matches ? "dark" : "light")
    }

    mediaQuery.addEventListener("change", handleChange)
    return () => mediaQuery.removeEventListener("change", handleChange)
  }, [theme])

  const setTheme = async (newTheme: Theme) => {
    startTransition(async () => {
      setThemeState(newTheme)
      await setThemeAction(newTheme)
    })
  }

  const value = {
    theme,
    setTheme,
    isUpdating: isPending,
  }

  return (
    <ThemeProviderContext.Provider {...props} value={value}>
      {children}
    </ThemeProviderContext.Provider>
  )
}

export const useTheme = () => {
  const context = useContext(ThemeProviderContext)

  if (context === undefined)
    throw new Error("useTheme must be used within a ThemeProvider")

  return context
} 