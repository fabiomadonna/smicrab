import { CreateAnalysisButton } from "@/components/analysis/create-analysis-button";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  ArrowRight,
  FileText,
  Plus,
  Clock,
  CheckCircle,
  AlertCircle,
  Calendar,
  BarChart3,
} from "lucide-react";
import Link from "next/link";
import { getCurrentUser } from "@/actions/auth.actions";
import { getUserAnalysesAction } from "@/actions/analysis.actions";
import { Analysis, AnalyzeStatus } from "@/types/analysis";

export default async function DashboardPage() {
  const user = await getCurrentUser();

  // Fetch user's analyses
  let analyses: Analysis[] = [];
  let analysisStats = {
    total: 0,
    inProgress: 0,
    completed: 0,
    failed: 0,
    configured: 0,
  };

  if (user?.user_id) {
    const analysesResponse = await getUserAnalysesAction(user.user_id);
    if (analysesResponse.success && analysesResponse.data) {
      analyses = analysesResponse.data;

      // Calculate statistics
      analysisStats = {
        total: analyses.length,
        inProgress: analyses.filter(
          (a) => a.status === AnalyzeStatus.IN_PROGRESS
        ).length,
        completed: analyses.filter((a) => a.status === AnalyzeStatus.COMPLETED)
          .length,
        failed: analyses.filter((a) => a.status === AnalyzeStatus.ERROR).length,
        configured: analyses.filter(
          (a) => a.status === AnalyzeStatus.CONFIGURED
        ).length,
      };
    }
  }

  // Get recent analyses (last 5)
  const recentAnalyses = analyses
    .sort(
      (a, b) =>
        new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
    )
    .slice(0, 5);

  return (
    <div className="flex-1 p-6 space-y-8 overflow-auto">
      <div>
        <h1 className="text-3xl font-bold">Dashboard</h1>
        <p className="text-muted-foreground">
          Welcome back, {user?.email}. Manage your spatial-temporal analyses and
          explore SMICRAB modules.
        </p>
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              Total Analyses
            </CardTitle>
            <FileText className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{analysisStats.total}</div>
            <p className="text-xs text-muted-foreground">
              {analysisStats.total === 0
                ? "No analyses yet"
                : `${analysisStats.total} total analyses`}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">In Progress</CardTitle>
            <Clock className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{analysisStats.inProgress}</div>
            <p className="text-xs text-muted-foreground">
              {analysisStats.inProgress === 0
                ? "No active analyses"
                : `${analysisStats.inProgress} running`}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Completed</CardTitle>
            <CheckCircle className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{analysisStats.completed}</div>
            <p className="text-xs text-muted-foreground">
              {analysisStats.completed === 0
                ? "No completed analyses"
                : `${analysisStats.completed} finished`}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Failed</CardTitle>
            <AlertCircle className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{analysisStats.failed}</div>
            <p className="text-xs text-muted-foreground">
              {analysisStats.failed === 0
                ? "No failed analyses"
                : `${analysisStats.failed} failed`}
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Quick Actions */}
      <div className="space-y-6 grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card className="h-full">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Plus className="h-5 w-5" />
              New Analysis
            </CardTitle>
            <CardDescription>Configure and start your analysis</CardDescription>
          </CardHeader>
          <CardContent className="flex-1">
            <p className="text-sm text-muted-foreground">
              Set up your analysis parameters including model type, variables,
              coordinates, and options.
            </p>
          </CardContent>
          <CardFooter>
            <CreateAnalysisButton userId={user?.user_id || ""} />
          </CardFooter>
        </Card>

        <Card className="h-full">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <FileText className="h-5 w-5" />
              All Analyses
            </CardTitle>
            <CardDescription>
              View and manage your analysis sessions
            </CardDescription>
          </CardHeader>
          <CardContent className="flex-1">
            <p className="text-sm text-muted-foreground">
              Access your existing analysis sessions, view results, and manage
              configurations.
            </p>
          </CardContent>
          <CardFooter>
            <Button asChild variant="secondary" className="w-full">
              <Link href="/analyses">
                View Analyses
                <ArrowRight className="h-4 w-4 ml-2" />
              </Link>
            </Button>
          </CardFooter>
        </Card>

        <Card className="h-full">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <BarChart3 className="h-5 w-5" />
              Datasets
            </CardTitle>
            <CardDescription>Explore available datasets</CardDescription>
          </CardHeader>
          <CardContent className="flex-1">
            <p className="text-sm text-muted-foreground">
              Browse and download available spatial-temporal datasets for your
              analyses.
            </p>
          </CardContent>
          <CardFooter>
            <Button asChild variant="outline" className="w-full">
              <Link href="/datasets">
                Browse Datasets
                <ArrowRight className="h-4 w-4 ml-2" />
              </Link>
            </Button>
          </CardFooter>
        </Card>
      </div>
    </div>
  );
}
