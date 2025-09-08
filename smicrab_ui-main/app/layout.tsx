import type { Metadata } from "next";
import { Inter } from "next/font/google"; // Import Inter from Google Fonts
import { Toaster } from "sonner";
import "./globals.css";
import { ThemeProvider } from "@/components/theme-provider";
import { getTheme } from "@/lib/theme-actions";
// Configure Inter font
const inter = Inter({
  subsets: ["latin"], // Specify the character subsets you need
  variable: "--font-inter", // CSS variable for Inter
  weight: ["100", "200", "300", "400", "500", "600", "700", "800", "900"], // Specify desired weights
});

export const metadata: Metadata = {
  title: "SMICRAB GUI - Spatial-Temporal Analysis Platform",
  description:
    "Advanced spatial-temporal data analysis interface for environmental research",
};

export default async function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const serverTheme = await getTheme();

  return (
    <html lang="en" className={serverTheme}>
      <body className={`${inter.variable} antialiased`}>
        <ThemeProvider defaultTheme={serverTheme}>
          {children}
          <Toaster
            richColors
            position="bottom-right"
            toastOptions={{
              duration: 4000,
            }}
          />
        </ThemeProvider>
      </body>
    </html>
  );
}
