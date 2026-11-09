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

---

## Fase 1 · Arranque: hacerlo a mano

### Evidencias

```text
$ docker run -d --name clickops-g1 -p 8090:80 nginx:1.27-alpine
bde43969d69aadd9024d6444b5b4af737d30d987310d856723f2c2b82db3a94d

$ curl -s http://localhost:8090 | head -5
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
```

Segundo intento con el mismo comando:

```text
$ docker run -d --name clickops-g1 -p 8090:80 nginx:1.27-alpine
docker: Error response from daemon: Conflict. The container name "/clickops-g1" is already in use by container "bde43969d69aadd9024d6444b5b4af737d30d987310d856723f2c2b82db3a94d". You have to remove (or rename) that container to be able to reuse that name.
```

Con otro nombre y el mismo puerto:

```text
$ docker run -d --name clickops-g1-2 -p 8090:80 nginx:1.27-alpine
d30e027de2eda65713f33261aec3c82dea0c043e133f06a8e8448e837dceaf76
docker: Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint clickops-g1-2 (...): Bind for 0.0.0.0:8090 failed: port is already allocated
```

Ojo que en este caso Docker sí alcanzó a crear el contenedor `clickops-g1-2` (devolvió el id), pero quedó sin arrancar porque el puerto ya estaba ocupado. O sea, quedó basura a medias.

Limpieza:

```text
$ docker rm -f clickops-g1 clickops-g1-2
clickops-g1
clickops-g1-2

$ docker ps -a --filter name=clickops
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

**El mismo objetivo de dos formas**

Imperativa (pasos en orden):

1. Descargar la imagen `nginx:1.27-alpine`.
2. Crear un contenedor llamado `clickops-g1` con esa imagen.
3. Publicar el puerto 80 del contenedor en el 8090 del equipo.
4. Arrancar el contenedor en segundo plano.

Declarativa (resultado deseado):

> Debe existir un único servidor nginx 1.27 llamado `clickops-g1` respondiendo en http://localhost:8090.

### Respuestas

**1. ¿Qué error produjo el segundo `docker run`? ¿Qué dice eso sobre la idempotencia de un comando imperativo?**

Dio `Conflict. The container name "/clickops-g1" is already in use`. El comando no revisa si lo que queremos ya existe, simplemente intenta crear otra vez. Entonces no es idempotente: correrlo dos veces no da el mismo resultado, la segunda vez falla, y si le cambiamos el nombre intenta crear un segundo servidor (que también falló, pero por el puerto, y además dejó un contenedor creado a medias).

**2. Si otro grupo necesitara mañana un servidor idéntico, ¿qué tendrían que contarle y dónde quedó registrado lo que hicieron?**

Tendríamos que explicarle todo de memoria: la imagen y su versión exacta, el nombre, el puerto, que va con `-d`, y además que tenga cuidado con nombres y puertos repetidos. Lo que hicimos solo quedó en el historial de la terminal de quien tecleó, que no se versiona, no se comparte y se puede perder. No hay ningún archivo que lo describa.

**3. ¿Cuáles de los cuatro puntos de la diapositiva «Por qué duele» vivieron en esta fase?**

Prácticamente los cuatro. *Propenso a errores humanos*: nos tropezamos con el nombre repetido y el puerto ocupado. *Imposible de reproducir igual dos veces*: repetir el mismo comando no dio lo mismo. *Sin historial*: no queda registro de quién hizo qué, solo la terminal. *El conocimiento se va con la persona*: lo que sabe cómo quedó el servidor es el que lo tecleó.
