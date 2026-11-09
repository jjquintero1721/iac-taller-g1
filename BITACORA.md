# Bitácora · Taller IaC con Terraform · Grupo 1

Arquitectura de Software II · 2026-2

## Integrantes

- Juan Jose Quintero Velasquez
- Nicolas Santiago Carmona
- Brandon Ortiz Medina
- Johan Felipe Molina

Como el profe no nos asignó número de grupo, usamos el **1** (N = 1), así que los nombres quedan `web-g1`, `tf-state-g1`, etc.

## Rotación de roles

| Fase | Operador/a | Navegante | Revisor/a del plan | Bitácora |
|------|------------|-----------|--------------------|----------|
| 0 y 1 | Juan Jose Quintero | Nicolas Carmona | Brandon Ortiz | Johan Molina |
| 2 | Nicolas Carmona | Brandon Ortiz | Johan Molina | Juan Jose Quintero |
| 3 | Brandon Ortiz | Johan Molina | Juan Jose Quintero | Nicolas Carmona |
| 4 | Johan Molina | Juan Jose Quintero | Nicolas Carmona | Brandon Ortiz |
| 5 | Juan Jose Quintero | Nicolas Carmona | Brandon Ortiz | Johan Molina |
| 6 | Nicolas Carmona | Brandon Ortiz | Johan Molina | Juan Jose Quintero |
| 7 | Brandon Ortiz | Johan Molina | Juan Jose Quintero | Nicolas Carmona |
| 8 | Johan Molina | Juan Jose Quintero | Nicolas Carmona | Brandon Ortiz |
| 9 | Juan Jose Quintero | Nicolas Carmona | Brandon Ortiz | Johan Molina |

---

## Fase 0 · Preparación del entorno

### Evidencias

Terraform no estaba instalado, lo instalamos con `winget install Hashicorp.Terraform`.

```text
$ terraform -version
Terraform v1.17.0
on windows_amd64
```

```text
$ docker version
Client:
 Version:           29.6.1
 API version:       1.55
 Go version:        go1.26.4
 Git commit:        8900f1d
 Built:             Fri Jun 26 11:43:32 2026
 OS/Arch:           windows/amd64
 Context:           desktop-linux

Server: Docker Desktop 4.82.0 (233772)
 Engine:
  Version:          29.6.1
  API version:      1.55 (minimum version 1.40)
  Go version:       go1.26.4
  Git commit:       8ec5ab3
  Built:            Fri Jun 26 11:41:04 2026
  OS/Arch:          linux/amd64
  Experimental:     false
 containerd:
  Version:          v2.2.5
 runc:
  Version:          1.3.6
 docker-init:
  Version:          0.19.0
```

```text
$ git --version
git version 2.56.0.windows.2
```

Imágenes descargadas: `nginx:1.27-alpine`, `nginx:1.28-alpine` y `postgres:17-alpine`.

Nota: Docker Desktop no arrancaba al principio, se cerraba con un error del "Inference manager" porque había un socket viejo trabado en `%LOCALAPPDATA%\Docker\run\dockerInference`. Lo solucionamos cerrando Docker, renombrando esa carpeta `run` a `run.old` y volviendo a abrirlo (Docker la crea de nuevo).

### Respuestas

Esta fase no tiene preguntas.
