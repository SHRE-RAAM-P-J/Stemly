import os
import json
from typing import Dict, Any
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain.prompts import PromptTemplate
from langchain.output_parsers import PydanticOutputParser
from pydantic import BaseModel, Field
from config import GEMINI_API_KEY

class ParameterUpdate(BaseModel):
    updated_parameters: Dict[str, Any] = Field(description="Dictionary of updated parameter values")
    explanation: str = Field(description="Brief explanation of what was changed")

async def adjust_parameters_with_ai(template_id: str, current_params: Dict[str, Any], user_prompt: str) -> Dict[str, Any]:
    """
    Uses Gemini to interpret user prompt and update visualiser parameters.
    """
    try:
        if not GEMINI_API_KEY:
            print("⚠ GEMINI_API_KEY not set")
            return {}

        llm = ChatGoogleGenerativeAI(
            model="gemini-pro", 
            temperature=0.0,
            google_api_key=GEMINI_API_KEY
        )
        
        parser = PydanticOutputParser(pydantic_object=ParameterUpdate)
        
        prompt = PromptTemplate(
            template="""
            You are an AI physics assistant controlling a simulation.
            
            Current Simulation: {template_id}
            Current Parameters: {current_params}
            
            User Request: "{user_prompt}"
            
            Your task is to update the parameters based on the user's request.
            - Only change parameters that are relevant to the request.
            - Keep other parameters as they are (or don't include them in the update).
            - Ensure values are physically reasonable.
            - If the user asks for something impossible or unrelated, return an empty dictionary for updated_parameters.
            
            {format_instructions}
            """,
            input_variables=["template_id", "current_params", "user_prompt"],
            partial_variables={"format_instructions": parser.get_format_instructions()}
        )
        
        chain = prompt | llm | parser
        
        result = await chain.ainvoke({
            "template_id": template_id,
            "current_params": current_params,
            "user_prompt": user_prompt
        })
        
        return result.updated_parameters
        
    except Exception as e:
        print(f"AI Parameter Adjustment Error: {e}")
        return {}
