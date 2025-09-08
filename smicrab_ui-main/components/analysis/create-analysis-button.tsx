"use client";

import { createAnalysisAction } from "@/actions";
import { Button } from "@/components/ui/button";
import { ArrowRight, Loader2, Plus } from "lucide-react";
import { useRouter } from "next/navigation";
import { useState, useTransition } from "react";
import { toast } from "sonner";

interface CreateAnalysisButtonProps {
  userId: string;
  variant?: "default" | "outline" | "secondary" | "ghost" | "link" | "destructive";
  className?: string;
  iconType?: "arrow" | "plus";
  children?: React.ReactNode;
}

export function CreateAnalysisButton({ 
  userId, 
  variant = "secondary",
  className = "w-full",
  iconType = "arrow",
  children
}: CreateAnalysisButtonProps) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();

  const handleCreateAnalysis = async () => {
    startTransition(async () => {
      try {
        const response = await createAnalysisAction(userId);
        
        if (response.success && response.data) {
          // Navigate to the new analysis configuration page
          router.push(`/analysis/${response.data.id}`);
          
          toast.success("Analysis created successfully", {
            description: "Please configure your analysis parameters."
          });
        } else {
          const errorMessage = typeof response.error === 'string' 
            ? response.error 
            : Array.isArray(response.error) 
              ? response.error.map(e => `${e.field}: ${e.message}`).join(', ')
              : "Failed to create analysis";
          
          toast.error(errorMessage, {
            description: "Please try again or contact support."
          });
        }
      } catch (error) {
        console.error("Analysis creation error:", error);
        toast.error("Failed to create analysis", {
          description: error instanceof Error ? error.message : "An unexpected error occurred"
        });
      }
    });
  };

  return (
    <Button 
      onClick={handleCreateAnalysis} 
      variant={variant} 
      className={className}
      disabled={isPending}
    >
      {isPending ? (
        <>
          <Loader2 className="h-4 w-4 animate-spin" />
          Creating...
        </>
      ) : (
        <>
          {iconType === "plus" && <Plus className="h-4 w-4" />}
          {children || "Start New Analysis"}
          {iconType === "arrow" && <ArrowRight className="h-4 w-4" />}
        </>
      )}
    </Button>
  );
} 