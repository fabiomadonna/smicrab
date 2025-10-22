"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogClose,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import {
  Loader2,
  Plus,
  Calendar,
  MapPin,
  Settings,
  RefreshCw,
  Eye,
  Trash2,
  AlertTriangle,
} from "lucide-react";
import { Analysis, AnalyzeStatus } from "@/types";
import { CreateAnalysisButton } from "./create-analysis-button";
import {
  createAnalysisAction,
  refreshAnalysesAction,
  deleteAnalysisAction,
} from "@/actions";

interface AnalysesListProps {
  analyses: Analysis[];
  userId: string;
}

export function AnalysesList({
  analyses: initialAnalyses,
  userId,
}: AnalysesListProps) {
  const [analyses, setAnalyses] = useState<Analysis[]>(initialAnalyses);
  const [isPending, startTransition] = useTransition();
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [isDeleting, setIsDeleting] = useState<string | null>(null);
  const router = useRouter();

  const getStatusColor = (status: AnalyzeStatus) => {
    switch (status) {
      case AnalyzeStatus.CONFIGURED:
        return "bg-yellow-50 text-yellow-700 border-yellow-200";
      case AnalyzeStatus.IN_PROGRESS:
        return "bg-blue-100 text-blue-800 border-blue-200";
      case AnalyzeStatus.COMPLETED:
        return "bg-green-100 text-green-800 border-green-200";
      case AnalyzeStatus.ERROR:
        return "bg-red-100 text-red-800 border-red-200";
      default:
        return "bg-gray-100 text-gray-800 border-gray-200";
    }
  };

  const getStatusText = (status: AnalyzeStatus) => {
    switch (status) {
      case AnalyzeStatus.COMPLETED:
        return "Completed";
      case AnalyzeStatus.IN_PROGRESS:
        return "In Progress";
      case AnalyzeStatus.ERROR:
        return "Error";
      case AnalyzeStatus.PENDING:
        return "Pending";
      case AnalyzeStatus.CONFIGURED:
        return "Configured";
      default:
        return "Unknown";
    }
  };

  const handleRefreshAnalyses = async () => {
    setIsRefreshing(true);
    try {
      const response = await refreshAnalysesAction(userId);

      if (response.success && response.data) {
        setAnalyses(response.data);
        toast.success("Analyses refreshed successfully");
      } else {
        const errorMessage =
          typeof response.error === "string"
            ? response.error
            : Array.isArray(response.error)
            ? response.error.map((e) => `${e.field}: ${e.message}`).join(", ")
            : "Failed to refresh analyses";

        toast.error(errorMessage);
      }
    } catch (error) {
      console.error("Error refreshing analyses:", error);
      toast.error("Failed to refresh analyses");
    } finally {
      setIsRefreshing(false);
    }
  };

  const handleCreateNewAnalysis = async () => {
    startTransition(async () => {
      try {
        const response = await createAnalysisAction(userId);

        if (response.success && response.data) {
          setAnalyses((prev) => [response.data!, ...prev]);
          router.push(`/analysis/${response.data.id}/configure`);
          toast.success("Analysis created successfully");
        } else {
          const errorMessage =
            typeof response.error === "string"
              ? response.error
              : Array.isArray(response.error)
              ? response.error.map((e) => `${e.field}: ${e.message}`).join(", ")
              : "Failed to create analysis";

          toast.error(errorMessage);
        }
      } catch (error) {
        console.error("Error creating analysis:", error);
        toast.error("Failed to create analysis");
      }
    });
  };

  const handleAnalysisClick = (analysis: Analysis) => {
    router.push(`/analysis/${analysis.id}`);
  };

  const handleDeleteAnalysis = async (analysisId: string) => {
    setIsDeleting(analysisId);
    try {
      const response = await deleteAnalysisAction(analysisId);

      if (response.success && response.data) {
        setAnalyses((prev) =>
          prev.filter((analysis) => analysis.id !== analysisId)
        );
        toast.success("Analysis deleted successfully");
      } else {
        const errorMessage =
          typeof response.error === "string"
            ? response.error
            : Array.isArray(response.error)
            ? response.error.map((e) => `${e.field}: ${e.message}`).join(", ")
            : "Failed to delete analysis";

        toast.error(errorMessage);
      }
    } catch (error) {
      console.error("Error deleting analysis:", error);
      toast.error("Failed to delete analysis");
    } finally {
      setIsDeleting(null);
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString("en-US", {
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  };

  const isAnalysisRunning = (analysis: Analysis) => {
    return analysis.status === AnalyzeStatus.IN_PROGRESS;
  };

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center gap-2">
        <div>
          <h2 className="text-2xl font-semibold">Your Analyses</h2>
          <p className="text-muted-foreground">
            Manage and track your spatial-temporal analysis sessions
          </p>
        </div>
        <div className="flex gap-2">
          <Button
            variant="ghost"
            onClick={handleRefreshAnalyses}
            disabled={isRefreshing}
          >
            <RefreshCw
              className={`w-4 h-4 ${isRefreshing ? "animate-spin" : ""}`}
            />
            Refresh
          </Button>
          <CreateAnalysisButton
            userId={userId}
            variant="default"
            className="w-auto"
            iconType="plus"
          >
            New Analysis
          </CreateAnalysisButton>
        </div>
      </div>

      {analyses.length === 0 ? (
        <Card>
          <CardContent className="flex flex-col items-center justify-center py-16">
            <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mb-4">
              <Settings className="w-8 h-8 text-gray-400" />
            </div>
            <h3 className="text-lg font-semibold mb-2">No analyses yet</h3>
            <p className="text-muted-foreground text-center mb-6 max-w-md">
              Start your first spatial-temporal analysis to explore
              environmental data patterns and relationships.
            </p>
            <CreateAnalysisButton
              userId={userId}
              variant="default"
              className="w-auto"
              iconType="plus"
            >
              Create Your First Analysis
            </CreateAnalysisButton>
          </CardContent>
        </Card>
      ) : (
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Analysis ID</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>Model Type</TableHead>
              <TableHead>Created At</TableHead>
              <TableHead>Location</TableHead>
              <TableHead>Configuration</TableHead>
              <TableHead>Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {analyses.map((analysis) => (
              <TableRow key={analysis.id}>
                <TableCell>{analysis.id.slice(-8)}</TableCell>
                <TableCell>
                  <Badge
                    variant="outline"
                    className={getStatusColor(analysis.status)}
                  >
                    {getStatusText(analysis.status)}
                  </Badge>
                </TableCell>
                <TableCell>{analysis.model_type || "Not configured"}</TableCell>
                <TableCell>{formatDate(analysis.created_at)}</TableCell>
                <TableCell>
                  {analysis.coordinates
                    ? `${analysis.coordinates.latitude?.toFixed(
                        2
                      )}, ${analysis.coordinates.longitude?.toFixed(2)}`
                    : "N/A"}
                </TableCell>
                <TableCell>
                  {analysis.model_config_data
                    ? "Configured"
                    : "Configuration Required"}
                </TableCell>
                <TableCell>
                  <div className="flex gap-2">
                    <Dialog>
                      <DialogTrigger asChild>
                        <Button
                          variant="outline"
                          size="sm"
                          disabled={isDeleting === analysis.id}
                          className="text-red-600 hover:text-red-700 dark:text-red-400 dark:hover:text-red-500"
                        >
                          {isDeleting === analysis.id ? (
                            <Loader2 className="w-4 h-4 animate-spin" />
                          ) : (
                            <Trash2 className="w-4 h-4" />
                          )}
                          Delete
                        </Button>
                      </DialogTrigger>
                      <DialogContent className="!bg-background p-8">
                        <DialogHeader>
                          <DialogTitle className="flex items-center gap-2">
                            <AlertTriangle className="w-5 h-5 text-red-600 dark:text-red-400" />
                            Delete Analysis
                          </DialogTitle>
                          {isAnalysisRunning(analysis) ? (
                            <div className="space-y-2">
                              <DialogDescription className="text-red-600 dark:text-red-400 font-medium">
                                ⚠️ Warning: This analysis is currently running!
                              </DialogDescription>

                              <DialogDescription>
                                Deleting a running analysis will stop the
                                execution and permanently remove all associated
                                data. This action cannot be undone.
                              </DialogDescription>
                              <DialogDescription>
                                Are you sure you want to delete analysis{" "}
                                <strong>{analysis.id.slice(-8)}</strong>?
                              </DialogDescription>
                            </div>
                          ) : (
                            <div className="space-y-2">
                              <DialogDescription>
                                This action will permanently delete the analysis
                                and all associated data. This action cannot be
                                undone.
                              </DialogDescription>
                              <DialogDescription>
                                Are you sure you want to delete analysis{" "}
                                <strong>{analysis.id.slice(-8)}</strong>?
                              </DialogDescription>
                            </div>
                          )}
                        </DialogHeader>
                        <DialogFooter>
                          <DialogClose asChild>
                            <Button variant="outline">Cancel</Button>
                          </DialogClose>
                          <Button
                            onClick={() => handleDeleteAnalysis(analysis.id)}
                            className="bg-red-600 hover:bg-red-700 dark:bg-red-400 dark:hover:bg-red-500 text-white"
                          >
                            {isDeleting === analysis.id ? (
                              <>
                                <Loader2 className="w-4 h-4 animate-spin" />
                                Deleting...
                              </>
                            ) : (
                              "Delete Analysis"
                            )}
                          </Button>
                        </DialogFooter>
                      </DialogContent>
                    </Dialog>
                    <Button
                      variant="default"
                      className="!px-4"
                      size="sm"
                      onClick={() => handleAnalysisClick(analysis)}
                    >
                      <Eye className="w-4 h-4" /> View
                    </Button>
                  </div>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      )}
    </div>
  );
}
