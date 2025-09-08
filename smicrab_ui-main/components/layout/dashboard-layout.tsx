"use client";

import React, { useState } from "react";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { ThemeToggle } from "@/components/theme-toggle";
import {
  LogOut,
  ChevronRight,
  Home,
  User,
  List,
  Database,
} from "lucide-react";
import { cn } from "@/lib/utils";
import Link from "next/link";
import { logoutUser } from "@/actions/auth.actions";
import { useRouter } from "next/navigation";
import { toast } from "sonner";

interface DashboardLayoutProps {
  children: React.ReactNode;
  currentUser?: {
    id: string;
    email: string;
  };
}

export function DashboardLayout({ children, currentUser }: DashboardLayoutProps) {
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const [isLoggingOut, setIsLoggingOut] = useState(false);
  const router = useRouter();

  const handleLogout = async () => {
    setIsLoggingOut(true);
    
    try {
      const result = await logoutUser();
      
      if (result.success) {
        toast.success("Logged out successfully");
        // Redirect to login page
        router.push('/login');
        router.refresh();
      } else {
        toast.error(result.message || "Logout failed");
      }
    } catch (error) {
      console.error('Logout error:', error);
      toast.error("An error occurred during logout");
    } finally {
      setIsLoggingOut(false);
    }
  };

  return (
    <div className="flex h-screen">
      {/* Sidebar */}
      <div
        className={cn(
          "flex flex-col border-r bg-card transition-all duration-300",
          sidebarCollapsed ? "w-16" : "w-64"
        )}
      >
        {/* Header */}
        <div className="p-4 border-b">
          <div className="flex items-center justify-between">
            {!sidebarCollapsed && (
              <div>
                <h1 className="text-xl font-bold text-primary">SMICRAB</h1>
                <p className="text-xs text-muted-foreground">
                  Analysis Platform
                </p>
              </div>
            )}
            <Button
              variant="ghost"
              size="sm"
              onClick={() => setSidebarCollapsed(!sidebarCollapsed)}
              className="h-8 w-8 p-0"
            >
              <ChevronRight
                className={cn(
                  "h-4 w-4 transition-transform",
                  sidebarCollapsed ? "rotate-0" : "rotate-180"
                )}
              />
            </Button>
          </div>
        </div>

        {/* Navigation */}
        <div className="flex-1 p-4 space-y-2">
          <Button
            variant="ghost"
            className={cn(
              "w-full justify-start",
              sidebarCollapsed ? "px-2" : "px-3"
            )}
            asChild
          >
            <Link href="/dashboard">
              <Home className="h-4 w-4" />
              {!sidebarCollapsed && <span className="ml-2">Dashboard</span>}
            </Link>
          </Button>

          <Button
            variant="ghost"
            className={cn(
              "w-full justify-start",
              sidebarCollapsed ? "px-2" : "px-3"
            )}
            asChild
          >
            <Link href="/analyses">
              <List className="h-4 w-4" />
              {!sidebarCollapsed && <span className="ml-2">Analyses</span>}
            </Link>
          </Button>

          {!sidebarCollapsed && <Separator className="my-4" />}

          <Button
            variant="ghost"
            className={cn(
              "w-full justify-start",
              sidebarCollapsed ? "px-2" : "px-3"
            )}
            asChild
          >
            <Link href="/datasets">
              <Database className="h-4 w-4" />
              {!sidebarCollapsed && <span className="ml-2">Datasets</span>}
            </Link>
          </Button>
        </div>

        {/* User Section */}
        <div className="p-4 border-t">
          {!sidebarCollapsed && currentUser && (
            <div className="mb-3">
              <Card className="p-3">
                <div className="flex items-center space-x-2">
                  <User className="h-4 w-4 text-muted-foreground" />
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium truncate">
                      {currentUser.email}
                    </p>
                    <p className="text-xs text-muted-foreground">Logged in</p>
                  </div>
                </div>
              </Card>
            </div>
          )}

          <div className="space-y-2">
            {!sidebarCollapsed && (
              <div className="flex items-center justify-between">
                <span className="text-xs text-muted-foreground">Theme</span>
                <ThemeToggle />
              </div>
            )}

            <Button
              variant="ghost"
              className={cn(
                "w-full justify-start text-destructive hover:text-destructive hover:bg-destructive/10",
                sidebarCollapsed ? "px-2" : "px-3"
              )}
              onClick={handleLogout}
              disabled={isLoggingOut}
            >
              <LogOut className={cn("h-4 w-4", isLoggingOut && "animate-spin")} />
              {!sidebarCollapsed && (
                <span className="ml-2">
                  {isLoggingOut ? "Logging out..." : "Logout"}
                </span>
              )}
            </Button>
          </div>
        </div>
      </div>

      {/* Main Content */}
      {children}
    </div>
  );
}
