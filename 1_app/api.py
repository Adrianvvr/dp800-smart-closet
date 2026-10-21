from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import pyodbc

app = FastAPI(title="SmartCloset RAG API")

class Consulta(BaseModel):
    pregunta: str
    usuario_id: int = 1  # Por defecto usamos a Lucía (ID 1)

@app.post("/preguntar")
def preguntar_estilista(consulta: Consulta):
    try:
    
        conn = pyodbc.connect(
            "DRIVER={ODBC Driver 17 for SQL Server};"
            "SERVER=localhost;"
            "DATABASE=SmartClosetAI;"
            "Trusted_Connection=yes;"
        )
        cursor = conn.cursor()
        
        sql = "EXEC dbo.usp_ConsultarEstilistaRAG @PreguntaUsuario = ?, @UsuarioID = ?"
        cursor.execute(sql, consulta.pregunta, consulta.usuario_id)
        
        cursor.nextset()
        
        row = cursor.fetchone()
        
        if row:
            respuesta = {
                "pregunta": row[0],
                "contexto": row[1],
                "respuesta_llm": row[2]
            }
        else:
            respuesta = {"error": "No se obtuvieron resultados."}
            
        cursor.close()
        conn.close()
        return respuesta

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))