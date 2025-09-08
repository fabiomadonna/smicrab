import { getUserAnalysesAction } from "@/actions";
import { AnalysesList } from "@/components/analysis/analyses-list";
import { getCurrentUser } from "@/actions/auth.actions";
import { redirect } from "next/navigation";

export default async function AnalysesPage() {
  const user = await getCurrentUser();
  
  if (!user) {
    redirect('/login');
  }

  // Fetch analyses for the user
  const response = await getUserAnalysesAction(user.user_id);
  const analyses = response.success && response.data ? response.data : [];

  // console.log("analyses");
  // console.log(analyses);
  return (
    <AnalysesList userId={user.user_id} analyses={analyses} />
  );
} 