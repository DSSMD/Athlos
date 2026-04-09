# Guía de Contribución - [SISTEMA ATHLOS]

¡Bienvenido! Para mantener la calidad del código y un flujo de trabajo ordenado, seguimos la metodología **GitFlow** y ciertas reglas de colaboración.

## 1. Flujo de Trabajo (GitFlow)

Utilizamos un modelo de ramificación basado en GitFlow. Las ramas principales son:

* **`main`**: Contiene el código estable en producción. **Protegida:** No se permite push directo.
* **`develop`**: Rama principal de integración. Aquí se fusionan todas las nuevas funcionalidades. **Protegida:** No se permite push directo.



## 2. Convención de Nombres de Ramas

Para crear una nueva rama, utiliza siempre el prefijo correspondiente seguido de una descripción breve en minúsculas y separada por guiones:

| Tipo de rama | Prefijo | Ejemplo |
| :--- | :--- | :--- |
| Nueva funcionalidad | `feature/` | `feature/login-supabase` |
| Corrección de errores | `bugfix/` | `bugfix/error-calculo-iva` |
| Arreglo crítico (prod) | `hotfix/` | `hotfix/caida-sesion-usuario` |
| Documentación | `docs/` | `docs/update-readme` |

## 3. Proceso de Pull Request (PR)

Para integrar cambios a `develop` o `main`, es obligatorio seguir este proceso:

1.  **Sincronizar:** Asegúrate de que tu rama local esté actualizada con `develop`.
2.  **Push:** Sube tu rama al repositorio remoto.
3.  **Abrir PR:** Crea un Pull Request hacia la rama `develop`.
4.  **Revisión:** * Se requiere **al menos 3 aprobaciOones** de los compañeros de equipo.
    * No se puede realizar el "Merge" si hay comentarios pendientes de resolución.
5.  **Merge:** Una vez aprobado y pasadas las pruebas, se procederá a la integración.

## 4. Estilo de Commits

Te recomendamos usar mensajes claros y descriptivos. Ejemplo:
`feat: agregar validación de NIT en el sistema de facturación`

---
*Este documento es parte de los entregables de infraestructura del equipo.*