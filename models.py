"""
Pydantic data models for research paper categorization and Claude API response validation.
"""
from typing import Optional, Literal
from pydantic import BaseModel, Field, field_validator


class PaperCategorizationResponse(BaseModel):
    """
    Pydantic model for validating Claude API response structure.
    This ensures strict data validation before updating Airtable.
    """
    
    category: Literal[
        "Core Technology",
        "Use Case",
        "Market Research",
        "Regulatory",
        "Competitive Analysis",
        "Other"
    ] = Field(
        ...,
        description="Primary category of the research paper"
    )
    
    priority: Literal["High", "Medium", "Low"] = Field(
        ...,
        description="Priority level for review and implementation"
    )
    
    relevance_score: int = Field(
        ...,
        ge=0,
        le=10,
        description="Relevance score from 0-10"
    )
    
    potential_impact: str = Field(
        ...,
        min_length=10,
        max_length=500,
        description="Brief description of potential impact on the project"
    )
    
    key_idea: str = Field(
        ...,
        min_length=10,
        max_length=1000,
        description="Main idea or insight from the paper"
    )
    
    technical_approach: str = Field(
        ...,
        min_length=10,
        max_length=1000,
        description="Technical approach or methodology described"
    )
    
    implementation_notes: str = Field(
        ...,
        min_length=10,
        max_length=1000,
        description="Notes on how this could be implemented"
    )
    
    related_technologies: str = Field(
        ...,
        max_length=500,
        description="Comma-separated list of related technologies mentioned"
    )
    
    actionable_insights: str = Field(
        ...,
        min_length=10,
        max_length=1000,
        description="Specific actionable insights or next steps"
    )
    
    confidence_level: Literal["High", "Medium", "Low"] = Field(
        ...,
        description="AI's confidence level in the categorization"
    )
    
    summary: str = Field(
        ...,
        min_length=20,
        max_length=2000,
        description="Comprehensive summary of the paper"
    )
    
    @field_validator('related_technologies')
    @classmethod
    def validate_technologies(cls, v: str) -> str:
        """Ensure related technologies is a properly formatted list."""
        if v:
            technologies = [tech.strip() for tech in v.split(',') if tech.strip()]
            return ', '.join(technologies)
        return v


class PaperInput(BaseModel):
    """
    Input data model for a research paper to be categorized.
    """
    title: str = Field(..., min_length=1, max_length=500)
    year: Optional[int] = Field(None, ge=1900, le=2100)
    abstract: Optional[str] = Field(None, max_length=5000)
    elicit_id: Optional[str] = Field(None, max_length=200)
    authors: Optional[str] = Field(None, max_length=1000)
    url: Optional[str] = Field(None, max_length=1000)
    
    class Config:
        validate_assignment = True
