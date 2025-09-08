import { DashboardLayout } from "@/components/layout/dashboard-layout";
import { getCurrentUser } from "@/actions/auth.actions";
import { redirect } from "next/navigation";

export default async function DashboardRootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const user = await getCurrentUser();
  
  if (!user) {
    redirect('/login');
  }

  return (
    <DashboardLayout
      currentUser={{
        id: user.user_id,
        email: user.email,
      }}
    >
      <div className="flex-1 p-3 space-y-6 overflow-auto">{children}</div>
    </DashboardLayout>
  );
}
