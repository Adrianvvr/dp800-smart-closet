import streamlit as st
import requests

st.set_page_config(page_title="Mi Estilista RAG", page_icon="👗")
st.title("👗 Estilista Inteligente")
st.write("Conectado a SQL Server 2025 y Llama 3.2 local")

usuarios_db = {
    "Lucía Martín (ID: 1)": 1,
    "Carlos Gómez (ID: 2)": 2,
    "Elena Rostova (ID: 3)": 3,
    "Mateo Silva (ID: 4)": 4
}

st.sidebar.title("⚙️ Configuración")
usuario_seleccionado = st.sidebar.selectbox("¿Quién está preguntando?", list(usuarios_db.keys()))
usuario_id_actual = usuarios_db[usuario_seleccionado]

st.sidebar.info(f"El sistema usará Row-Level Security (RLS) para buscar exclusivamente en el armario del Usuario {usuario_id_actual}.")

if "mensajes" not in st.session_state:
    st.session_state.mensajes = []

for msg in st.session_state.mensajes:
    with st.chat_message(msg["rol"]):
        st.markdown(msg["contenido"])
    
        if "contexto" in msg and msg["contexto"]:
            with st.expander("🔍 Ver prendas encontradas en el armario (Grounding)"):
                st.text(msg["contexto"])

pregunta = st.chat_input("Ej: ¿Qué me pongo para una boda al mediodía?")

if pregunta:
    with st.chat_message("user"):
        st.markdown(pregunta)
    st.session_state.mensajes.append({"rol": "user", "contenido": pregunta})

    with st.chat_message("assistant"):
        with st.spinner("Buscando en tu armario y pensando..."):
            try:
                res = requests.post(
                    "http://127.0.0.1:8000/preguntar", 
                    json={
                        "pregunta": pregunta, 
                        "usuario_id": usuario_id_actual
                    }
                )
                
                if res.status_code == 200:
                    datos = res.json()
                    respuesta_llm = datos.get("respuesta_llm", "Sin respuesta.")
                    contexto = datos.get("contexto", "")
                    
                    st.markdown(respuesta_llm)
                    
                    
                    with st.expander("🔍 Ver prendas encontradas en el armario (Grounding)"):
                        st.text(contexto)
                        
                    st.session_state.mensajes.append({
                        "rol": "assistant", 
                        "contenido": respuesta_llm, 
                        "contexto": contexto
                    })
                else:
                    st.error("Error del servidor API.")
            except Exception as e:
                st.error("No se pudo conectar con la API. ¿Está uvicorn encendido?")