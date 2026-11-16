#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Genera el arte pixel-art de MYG-351: Last Signal (retratos, iconos, nave y fondos de final).

Uso (desde la carpeta del proyecto):
    python tools/generar_arte.py

Necesita Pillow:  pip install pillow

Todo se dibuja con codigo (formas simples + contorno automatico) para que el estilo sea
parejo. Si quieres reemplazar un dibujo por uno hecho a mano, solo guarda tu PNG con el
MISMO nombre y tamano en la carpeta assets/ y NO vuelvas a correr este script
(o borra esa parte del script).
"""
import math
import os
import random

from PIL import Image, ImageDraw

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(RAIZ, "assets")
CONTORNO = (18, 16, 34, 255)


# ----------------------------------------------------------------------------
# Utilidades
# ----------------------------------------------------------------------------
def lienzo(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def contorno(img, color=CONTORNO):
    """Agrega 1 px de contorno oscuro alrededor de la silueta (estilo de los iconos de la tienda)."""
    w, h = img.size
    src = img.load()
    out = img.copy()
    dst = out.load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] > 0:
                        dst[x, y] = color
                        break
    return out


def tono(img, cond, factor):
    """Aclara (factor > 1) u oscurece (factor < 1) los pixeles opacos donde cond(x, y) es verdadero."""
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a > 0 and cond(x, y):
                px[x, y] = (min(255, int(r * factor)), min(255, int(g * factor)), min(255, int(b * factor)), a)


def mezclar(c1, c2, t):
    return tuple(int(round(c1[i] + (c2[i] - c1[i]) * t)) for i in range(3))


def puntos(d, lista, color):
    for p in lista:
        d.point(p, fill=color)


def guardar(img, *ruta):
    destino = os.path.join(ASSETS, *ruta)
    os.makedirs(os.path.dirname(destino), exist_ok=True)
    img.save(destino)
    return destino


def estrella(cx, cy, r_ext, r_int, n, giro=-90.0):
    pts = []
    for i in range(n * 2):
        r = r_ext if i % 2 == 0 else r_int
        ang = math.radians(giro + i * 180.0 / n)
        pts.append((round(cx + r * math.cos(ang)), round(cy + r * math.sin(ang))))
    return pts


def prohibido(img):
    """Dibuja encima el simbolo rojo de 'prohibido' (aro + barra diagonal)."""
    d = ImageDraw.Draw(img)
    rojo = (226, 60, 60, 255)
    d.ellipse((2, 2, 29, 29), outline=rojo, width=3)
    d.line((7, 7, 24, 24), fill=rojo, width=3)
    return img


# ----------------------------------------------------------------------------
# Iconos 32x32
# ----------------------------------------------------------------------------
def icono_electricidad():
    img = lienzo(32, 32)
    d = ImageDraw.Draw(img)
    d.polygon([(19, 2), (7, 17), (14, 17), (11, 29), (25, 13), (17, 13), (22, 2)], fill=(255, 214, 48, 255))
    d.line((18, 4, 10, 15), fill=(255, 246, 170, 255))
    d.line((13, 18, 12, 24), fill=(255, 246, 170, 255))
    d.line((23, 14, 14, 26), fill=(238, 150, 36, 255))
    d.line((21, 4, 18, 12), fill=(238, 150, 36, 255))
    return contorno(img)


def icono_salud():
    img = lienzo(32, 32)
    d = ImageDraw.Draw(img)
    rojo = (228, 59, 68, 255)
    d.ellipse((4, 6, 16, 18), fill=rojo)
    d.ellipse((15, 6, 27, 18), fill=rojo)
    d.polygon([(4, 13), (27, 13), (16, 27), (15, 27)], fill=rojo)
    tono(img, lambda x, y: x + y > 36, 0.72)
    d.ellipse((7, 8, 11, 11), fill=(255, 150, 150, 255))
    return contorno(img)


def icono_comida():
    img = lienzo(32, 32)
    d = ImageDraw.Draw(img)
    rojo = (214, 58, 58, 255)
    d.ellipse((5, 9, 18, 28), fill=rojo)
    d.ellipse((13, 9, 26, 28), fill=rojo)
    tono(img, lambda x, y: x + y > 40, 0.72)
    d.ellipse((8, 12, 11, 17), fill=(255, 150, 140, 255))
    d.rectangle((15, 5, 16, 11), fill=(112, 72, 44, 255))
    d.polygon([(17, 8), (21, 3), (25, 4), (22, 8)], fill=(92, 176, 76, 255))
    d.line((18, 7, 23, 5), fill=(150, 214, 110, 255))
    return contorno(img)


def icono_oxigeno():
    img = lienzo(32, 32)
    d = ImageDraw.Draw(img)
    d.ellipse((3, 3, 28, 28), fill=(64, 190, 220, 255))
    tono(img, lambda x, y: x + y > 38, 0.75)
    d.arc((6, 6, 25, 25), 180, 270, fill=(190, 240, 250, 255), width=2)
    blanco = (244, 252, 255, 255)
    letra_o = [".####.", "##..##", "#....#", "#....#", "#....#", "#....#", "#....#", "##..##", ".####."]
    letra_2 = [".###.", "#...#", "....#", "..##.", ".#...", "#####"]
    for j, fila in enumerate(letra_o):
        for i, c in enumerate(fila):
            if c == "#":
                d.point((8 + i, 11 + j), fill=blanco)
    for j, fila in enumerate(letra_2):
        for i, c in enumerate(fila):
            if c == "#":
                d.point((17 + i, 17 + j), fill=blanco)
    return contorno(img)


def icono_combustible():
    img = lienzo(32, 32)
    d = ImageDraw.Draw(img)
    rojo = (214, 64, 56, 255)
    d.polygon([(6, 10), (19, 10), (25, 15), (25, 28), (6, 28)], fill=rojo)
    d.rectangle((8, 5, 17, 10), fill=rojo)
    d.rectangle((10, 7, 15, 9), fill=(0, 0, 0, 0))
    d.polygon([(20, 6), (24, 6), (26, 11), (22, 11)], fill=(170, 178, 196, 255))
    tono(img, lambda x, y: x + y > 44, 0.74)
    d.line((8, 12, 8, 26), fill=(240, 120, 110, 255))
    d.polygon([(15, 14), (19, 19), (19, 23), (17, 25), (13, 25), (11, 23), (12, 19)], fill=(255, 208, 64, 255))
    d.polygon([(15, 19), (17, 22), (16, 24), (14, 24), (13, 22)], fill=(255, 244, 190, 255))
    return contorno(img)


def icono_temperatura():
    img = lienzo(32, 32)
    d = ImageDraw.Draw(img)
    vidrio = (232, 238, 246, 255)
    rojo = (228, 59, 68, 255)
    d.rounded_rectangle((12, 2, 18, 22), radius=3, fill=vidrio)
    d.ellipse((9, 17, 21, 29), fill=vidrio)
    d.ellipse((11, 19, 19, 27), fill=rojo)
    d.rectangle((14, 9, 16, 20), fill=rojo)
    d.point((13, 21), fill=(255, 160, 160, 255))
    for y in (6, 10, 14):
        d.line((21, y, 24, y), fill=(170, 180, 200, 255))
    return contorno(img)


def icono_integridad():
    img = lienzo(32, 32)
    d = ImageDraw.Draw(img)
    d.polygon([(16, 2), (27, 6), (27, 15), (24, 22), (16, 29), (15, 29), (7, 22), (4, 15), (4, 6), (15, 2)], fill=(104, 140, 190, 255))
    d.polygon([(15, 2), (4, 6), (4, 15), (7, 22), (15, 29)], fill=(150, 184, 226, 255))
    d.line((9, 15, 13, 20), fill=(250, 252, 255, 255), width=3)
    d.line((13, 20, 22, 10), fill=(250, 252, 255, 255), width=3)
    return contorno(img)


def icono_datos():
    img = lienzo(32, 32)
    d = ImageDraw.Draw(img)
    d.polygon([(4, 4), (23, 4), (27, 8), (27, 27), (4, 27)], fill=(58, 110, 200, 255))
    tono(img, lambda x, y: x + y > 44, 0.75)
    d.rectangle((9, 4, 20, 11), fill=(204, 212, 224, 255))
    d.rectangle((16, 5, 18, 10), fill=(60, 70, 96, 255))
    d.rectangle((8, 16, 23, 27), fill=(238, 242, 248, 255))
    for y in (19, 22, 25):
        d.line((10, y, 21, y), fill=(140, 150, 170, 255))
    return contorno(img)


def icono_ciencia():
    img = lienzo(32, 32)
    d = ImageDraw.Draw(img)
    vidrio = (206, 232, 242, 255)
    d.rectangle((13, 4, 18, 12), fill=vidrio)
    d.rectangle((11, 2, 20, 4), fill=(236, 246, 252, 255))
    d.polygon([(13, 12), (18, 12), (27, 26), (26, 29), (5, 29), (4, 26)], fill=vidrio)
    d.polygon([(9, 19), (22, 19), (27, 26), (26, 29), (5, 29), (4, 26)], fill=(86, 208, 120, 255))
    tono(img, lambda x, y: y >= 19 and x + y > 44, 0.74)
    puntos(d, [(12, 23), (17, 25), (20, 22), (14, 16), (16, 9)], (220, 255, 226, 255))
    d.line((14, 6, 14, 11), fill=(244, 252, 255, 255))
    return contorno(img)


def icono_estres():
    img = lienzo(32, 32)
    d = ImageDraw.Draw(img)
    d.polygon(estrella(15.5, 15.5, 14, 8.5, 10), fill=(150, 92, 214, 255))
    tono(img, lambda x, y: x + y > 36, 0.74)
    d.rectangle((14, 8, 17, 18), fill=(250, 246, 255, 255))
    d.rectangle((14, 21, 17, 24), fill=(250, 246, 255, 255))
    return contorno(img)


def icono_hambre():
    img = lienzo(32, 32)
    d = ImageDraw.Draw(img)
    plata = (206, 214, 228, 255)
    sombra = (150, 160, 182, 255)
    for x in (6, 9, 12):
        d.rectangle((x, 3, x + 1, 11), fill=plata)
    d.rectangle((6, 11, 13, 13), fill=plata)
    d.rectangle((9, 13, 10, 28), fill=plata)
    d.line((10, 14, 10, 28), fill=sombra)
    d.polygon([(19, 3), (22, 3), (25, 7), (25, 17), (19, 17)], fill=plata)
    d.line((24, 8, 24, 16), fill=sombra)
    d.rectangle((19, 17, 22, 28), fill=(120, 84, 60, 255))
    d.line((22, 18, 22, 28), fill=(88, 60, 44, 255))
    return contorno(img)


def icono_confianza():
    img = lienzo(32, 32)
    d = ImageDraw.Draw(img)
    d.polygon(estrella(15.5, 16.5, 14, 6, 5), fill=(255, 204, 56, 255))
    tono(img, lambda x, y: x + y > 38, 0.76)
    d.line((14, 8, 11, 14), fill=(255, 244, 180, 255))
    return contorno(img)


def icono_reloj():
    img = lienzo(32, 32)
    d = ImageDraw.Draw(img)
    d.rectangle((14, 2, 17, 6), fill=(150, 160, 182, 255))
    d.rectangle((12, 1, 19, 2), fill=(190, 198, 214, 255))
    d.ellipse((4, 6, 27, 29), fill=(122, 134, 160, 255))
    d.ellipse((6, 8, 25, 27), fill=(238, 242, 248, 255))
    d.line((15, 18, 15, 11), fill=(40, 44, 64, 255), width=2)
    d.line((15, 18, 21, 18), fill=(226, 60, 60, 255), width=2)
    return contorno(img)


def icono_alarma():
    img = lienzo(32, 32)
    d = ImageDraw.Draw(img)
    d.polygon([(15, 3), (16, 3), (29, 27), (2, 27)], fill=(255, 208, 48, 255))
    tono(img, lambda x, y: y > 23, 0.8)
    d.rectangle((14, 10, 17, 19), fill=(44, 34, 24, 255))
    d.rectangle((14, 22, 17, 24), fill=(44, 34, 24, 255))
    return contorno(img)


def icono_memo():
    img = lienzo(32, 32)
    d = ImageDraw.Draw(img)
    d.polygon([(6, 2), (20, 2), (26, 8), (26, 29), (6, 29)], fill=(244, 240, 224, 255))
    d.polygon([(20, 2), (26, 8), (20, 8)], fill=(198, 192, 170, 255))
    d.rectangle((9, 5, 17, 8), fill=(48, 96, 190, 255))
    for y in (12, 15, 18, 21, 24):
        d.line((9, y, 23, y), fill=(128, 128, 140, 255))
    return contorno(img)


def icono_resultado(tipo):
    img = lienzo(32, 32)
    d = ImageDraw.Draw(img)
    blanco = (250, 252, 255, 255)
    if tipo == "bueno":
        d.ellipse((3, 3, 28, 28), fill=(64, 186, 104, 255))
        tono(img, lambda x, y: x + y > 38, 0.78)
        d.line((9, 16, 13, 21), fill=blanco, width=3)
        d.line((13, 21, 22, 10), fill=blanco, width=3)
    elif tipo == "intermedio":
        d.ellipse((3, 3, 28, 28), fill=(240, 166, 48, 255))
        tono(img, lambda x, y: x + y > 38, 0.78)
        d.rectangle((14, 8, 17, 18), fill=blanco)
        d.rectangle((14, 21, 17, 24), fill=blanco)
    else:
        d.ellipse((3, 3, 28, 28), fill=(220, 64, 64, 255))
        tono(img, lambda x, y: x + y > 38, 0.78)
        d.line((10, 10, 21, 21), fill=blanco, width=3)
        d.line((21, 10, 10, 21), fill=blanco, width=3)
    return contorno(img)


def icono_enlace():
    img = lienzo(32, 32)
    d = ImageDraw.Draw(img)
    gris = (190, 198, 214, 255)
    d.line((15, 13, 10, 29), fill=gris, width=2)
    d.line((16, 13, 21, 29), fill=gris, width=2)
    d.line((12, 22, 19, 22), fill=gris)
    d.line((11, 26, 20, 26), fill=gris)
    d.ellipse((13, 8, 18, 13), fill=(255, 208, 48, 255))
    cian = (90, 210, 240, 255)
    d.arc((7, 2, 24, 19), 200, 250, fill=cian, width=2)
    d.arc((7, 2, 24, 19), 290, 340, fill=cian, width=2)
    d.arc((2, -3, 29, 24), 205, 245, fill=cian, width=2)
    d.arc((2, -3, 29, 24), 295, 335, fill=cian, width=2)
    return contorno(img)


def icono_racion(nivel):
    img = lienzo(32, 32)
    d = ImageDraw.Draw(img)
    naranja = (240, 160, 60, 255)
    if nivel == "completa":
        d.ellipse((6, 6, 25, 24), fill=naranja)
        d.ellipse((9, 8, 13, 11), fill=(255, 214, 130, 255))
        puntos(d, [(15, 9), (19, 12), (11, 14), (21, 15)], (150, 200, 90, 255))
    elif nivel == "reducida":
        d.ellipse((9, 12, 22, 24), fill=naranja)
        d.ellipse((11, 14, 14, 16), fill=(255, 214, 130, 255))
        puntos(d, [(17, 15), (13, 17)], (150, 200, 90, 255))
    else:
        d.ellipse((12, 16, 19, 24), fill=naranja)
    d.chord((4, 9, 27, 31), 0, 180, fill=(150, 170, 204, 255))
    d.rectangle((3, 19, 28, 20), fill=(214, 224, 240, 255))
    tono(img, lambda x, y: y > 20 and x + y > 44, 0.76)
    return contorno(img)


def icono_higiene(suspendida):
    img = lienzo(32, 32)
    d = ImageDraw.Draw(img)
    gris = (190, 198, 214, 255)
    d.rectangle((13, 2, 15, 6), fill=gris)
    d.polygon([(8, 6), (20, 6), (23, 11), (5, 11)], fill=gris)
    d.line((6, 11, 22, 11), fill=(140, 150, 172, 255))
    azul = (110, 200, 250, 255)
    for (x, y) in [(8, 14), (14, 14), (20, 14), (11, 18), (17, 18), (8, 22), (14, 22), (20, 22), (11, 26), (17, 26)]:
        d.rectangle((x, y, x + 1, y + 2), fill=azul)
    img = contorno(img)
    if suspendida:
        img = prohibido(img)
    return img


def icono_instrumentos(modo):
    base = Image.open(os.path.join(ASSETS, "ui", "icono_instrumentos.png")).convert("RGBA")
    if modo == "apagados":
        px = base.load()
        for y in range(base.height):
            for x in range(base.width):
                r, g, b, a = px[x, y]
                gris = int((r + g + b) / 3 * 0.6)
                px[x, y] = (gris, gris, gris + 8, a)
        base = prohibido(base)
    elif modo == "todos":
        d = ImageDraw.Draw(base)
        amarillo = (255, 232, 96, 255)
        for (cx, cy) in [(5, 5), (26, 24), (25, 5)]:
            d.line((cx - 2, cy, cx + 2, cy), fill=amarillo)
            d.line((cx, cy - 2, cx, cy + 2), fill=amarillo)
    return base


def icono_sonido(activo):
    img = lienzo(32, 32)
    d = ImageDraw.Draw(img)
    blanco = (236, 242, 250, 255)
    d.polygon([(4, 12), (9, 12), (15, 6), (15, 25), (9, 19), (4, 19)], fill=blanco)
    if activo:
        cian = (110, 210, 250, 255)
        d.arc((12, 9, 22, 22), 300, 60, fill=cian, width=2)
        d.arc((12, 4, 28, 27), 305, 55, fill=cian, width=2)
    else:
        rojo = (226, 70, 70, 255)
        d.line((19, 11, 27, 19), fill=rojo, width=2)
        d.line((27, 11, 19, 19), fill=rojo, width=2)
    return contorno(img)


def icono_pulso(vivo):
    img = lienzo(32, 32)
    d = ImageDraw.Draw(img)
    if vivo:
        d.line([(2, 17), (8, 17), (11, 8), (15, 25), (18, 13), (20, 17), (29, 17)], fill=(96, 230, 130, 255), width=2)
    else:
        d.line([(2, 17), (29, 17)], fill=(226, 70, 70, 255), width=2)
        d.line((12, 9, 20, 13), fill=(226, 70, 70, 255))
        d.line((20, 9, 12, 13), fill=(226, 70, 70, 255))
    return contorno(img)


def icono_herramienta():
    """Llave inglesa (para los minijuegos de reparacion)."""
    img = lienzo(32, 32)
    d = ImageDraw.Draw(img)
    gris = (196, 204, 220, 255)
    d.line((9, 23, 21, 11), fill=gris, width=5)
    d.ellipse((17, 3, 29, 15), fill=gris)
    d.polygon([(23, 1), (31, 1), (31, 9), (26, 9), (23, 6)], fill=(0, 0, 0, 0))
    d.ellipse((3, 19, 13, 29), fill=gris)
    d.ellipse((6, 22, 10, 26), fill=(0, 0, 0, 0))
    tono(img, lambda x, y: x + y > 36, 0.74)
    d.line((10, 20, 19, 11), fill=(236, 240, 248, 255))
    return contorno(img)


def icono_flecha(arriba):
    """Flecha blanca (se tine de color en el juego): indica si algo sube o baja."""
    img = lienzo(32, 32)
    d = ImageDraw.Draw(img)
    blanco = (250, 252, 255, 255)
    if arriba:
        d.polygon([(15, 4), (16, 4), (27, 17), (20, 17), (20, 27), (11, 27), (11, 17), (4, 17)], fill=blanco)
    else:
        d.polygon([(15, 27), (16, 27), (27, 14), (20, 14), (20, 4), (11, 4), (11, 14), (4, 14)], fill=blanco)
    return contorno(img)


def icono_ayuda():
    """Signo de pregunta dentro de un circulo (boton de la guia)."""
    img = lienzo(32, 32)
    d = ImageDraw.Draw(img)
    d.ellipse((3, 3, 28, 28), fill=(64, 150, 230, 255))
    tono(img, lambda x, y: x + y > 38, 0.78)
    blanco = (250, 252, 255, 255)
    signo = [".######.", "##....##", "##....##", "......##", ".....##.", "....##..", "...##...", "...##...", "........", "...##...", "...##..."]
    for j, fila in enumerate(signo):
        for i, c in enumerate(fila):
            if c == "#":
                d.point((12 + i, 10 + j), fill=blanco)
    return contorno(img)


def icono_tierra_mini():
    img = lienzo(32, 32)
    d = ImageDraw.Draw(img)
    d.ellipse((3, 3, 28, 28), fill=(52, 116, 214, 255))
    verde = (86, 176, 84, 255)
    d.polygon([(8, 8), (14, 6), (17, 10), (13, 15), (8, 14)], fill=verde)
    d.polygon([(17, 17), (23, 15), (25, 20), (21, 25), (16, 23)], fill=verde)
    d.polygon([(6, 19), (10, 18), (11, 23), (8, 24)], fill=verde)
    blanco = (240, 248, 255, 255)
    d.line((18, 6, 24, 8), fill=blanco, width=2)
    d.line((5, 16, 10, 16), fill=blanco)
    d.line((12, 26, 18, 27), fill=blanco)
    tono(img, lambda x, y: x + y > 40, 0.66)
    return contorno(img)


def icono_luna_mini():
    img = lienzo(32, 32)
    d = ImageDraw.Draw(img)
    d.ellipse((3, 3, 28, 28), fill=(196, 198, 210, 255))
    crater = (150, 152, 170, 255)
    d.ellipse((8, 8, 13, 13), fill=crater)
    d.ellipse((17, 12, 23, 18), fill=crater)
    d.ellipse((10, 19, 14, 23), fill=crater)
    d.ellipse((20, 22, 23, 25), fill=crater)
    tono(img, lambda x, y: x + y > 40, 0.66)
    return contorno(img)


def icono_orion_mini():
    """Nave pequena para el mapa de trayectoria (mira hacia la derecha)."""
    img = lienzo(32, 32)
    d = ImageDraw.Draw(img)
    azul = (70, 120, 220, 255)
    d.rectangle((11, 2, 14, 10), fill=azul)
    d.rectangle((11, 21, 14, 29), fill=azul)
    d.line((11, 5, 14, 5), fill=(150, 190, 250, 255))
    d.line((11, 8, 14, 8), fill=(150, 190, 250, 255))
    d.line((11, 23, 14, 23), fill=(150, 190, 250, 255))
    d.line((11, 26, 14, 26), fill=(150, 190, 250, 255))
    d.polygon([(3, 12), (7, 13), (7, 18), (3, 19)], fill=(90, 96, 116, 255))
    d.rectangle((7, 11, 18, 20), fill=(214, 220, 232, 255))
    d.rectangle((9, 11, 10, 20), fill=(232, 190, 80, 255))
    d.rectangle((18, 10, 19, 21), fill=(60, 64, 84, 255))
    d.polygon([(20, 10), (27, 14), (28, 15), (28, 16), (27, 17), (20, 21)], fill=(236, 240, 246, 255))
    d.rectangle((22, 14, 23, 15), fill=(60, 110, 200, 255))
    tono(img, lambda x, y: 10 <= y and y > 17, 0.8)
    return contorno(img)


# ----------------------------------------------------------------------------
# Retratos 48x48 (4 tripulantes x 5 estados)
# ----------------------------------------------------------------------------
PERSONAJES = {
    "elena": {
        "piel": (226, 176, 134), "piel_s": (190, 136, 100), "piel_l": (244, 204, 166),
        "pelo": (62, 40, 32), "pelo_l": (104, 70, 52),
        "acento": (224, 86, 74), "labios": (170, 70, 70),
    },
    "marcus": {
        "piel": (240, 206, 170), "piel_s": (206, 166, 130), "piel_l": (252, 226, 196),
        "pelo": (30, 30, 40), "pelo_l": (66, 68, 92),
        "acento": (74, 144, 224), "labios": (156, 84, 76),
    },
    "sofia": {
        "piel": (216, 162, 120), "piel_s": (178, 124, 90), "piel_l": (236, 190, 150),
        "pelo": (142, 62, 40), "pelo_l": (190, 100, 60),
        "acento": (78, 201, 160), "labios": (190, 70, 84),
    },
    "leo": {
        "piel": (124, 82, 58), "piel_s": (94, 60, 42), "piel_l": (150, 104, 76),
        "pelo": (26, 24, 30), "pelo_l": (58, 54, 66),
        "acento": (240, 160, 48), "labios": (96, 48, 44),
    },
}
ESTADOS = ["normal", "estresado", "herido", "critico", "perdido"]


def retrato(nombre, estado):
    p = dict(PERSONAJES[nombre])
    expresion = "critico" if estado == "perdido" else estado
    if expresion == "critico":
        # Piel palida/enfermiza
        palido = (196, 206, 196)
        for k in ("piel", "piel_s", "piel_l"):
            p[k] = mezclar(p[k], palido, 0.42)
    piel, piel_s, piel_l = p["piel"] + (255,), p["piel_s"] + (255,), p["piel_l"] + (255,)
    pelo, pelo_l = p["pelo"] + (255,), p["pelo_l"] + (255,)
    acento = p["acento"] + (255,)
    labios = p["labios"] + (255,)
    oscuro = (44, 30, 36, 255)
    blanco_ojo = (250, 250, 252, 255)

    img = lienzo(48, 48)
    d = ImageDraw.Draw(img)

    # 1) Pelo de atras
    if nombre == "elena":
        d.ellipse((27, 1, 37, 11), fill=pelo)
        d.arc((28, 2, 36, 10), 200, 320, fill=pelo_l)
    elif nombre == "sofia":
        d.ellipse((9, 5, 38, 40), fill=pelo)
        d.ellipse((7, 28, 16, 43), fill=pelo)
        d.ellipse((31, 28, 40, 43), fill=pelo)
        d.line((10, 20, 9, 34), fill=pelo_l)
        d.line((37, 20, 38, 34), fill=pelo_l)
        d.line((12, 36, 13, 40), fill=pelo_l)
        d.line((35, 36, 34, 40), fill=pelo_l)

    # 2) Traje
    traje = (228, 232, 238, 255)
    traje_s = (182, 190, 206, 255)
    d.polygon([(2, 47), (4, 41), (9, 37), (16, 35), (31, 35), (38, 37), (43, 41), (45, 47)], fill=traje)
    d.polygon([(31, 35), (38, 37), (43, 41), (45, 47), (35, 47)], fill=traje_s)
    d.line((5, 41, 14, 36), fill=acento, width=2)
    d.line((42, 41, 33, 36), fill=acento, width=2)
    d.line((24, 40, 24, 47), fill=(150, 158, 176, 255))
    d.rectangle((8, 43, 12, 46), fill=acento)
    if nombre == "sofia":
        d.rectangle((33, 42, 38, 47), fill=(250, 250, 252, 255))
        d.rectangle((35, 42, 36, 47), fill=(226, 60, 60, 255))
        d.rectangle((33, 44, 38, 45), fill=(226, 60, 60, 255))
    elif nombre == "elena":
        d.rectangle((33, 43, 39, 44), fill=(255, 204, 56, 255))
        d.rectangle((33, 46, 39, 46), fill=(255, 204, 56, 255))
    else:
        d.rectangle((33, 43, 39, 45), fill=(48, 96, 190, 255))

    # 3) Anillo del casco y cuello
    d.ellipse((14, 31, 33, 40), fill=(152, 162, 182, 255))
    d.arc((14, 31, 33, 40), 180, 300, fill=(214, 222, 236, 255))
    d.ellipse((17, 32, 30, 38), fill=(70, 76, 98, 255))
    d.rectangle((20, 28, 27, 36), fill=piel_s)

    # 4) Cabeza
    d.rectangle((12, 19, 13, 23), fill=piel_s)
    d.rectangle((34, 19, 35, 23), fill=piel_s)
    d.ellipse((14, 9, 33, 32), fill=piel_s)
    d.ellipse((14, 9, 31, 31), fill=piel)
    d.ellipse((17, 13, 20, 15), fill=piel_l)

    # 5) Pelo de adelante
    if nombre == "elena":
        d.polygon([(13, 19), (14, 10), (18, 6), (24, 5), (30, 6), (34, 10), (35, 19), (33, 15), (31, 13), (26, 12),
                   (21, 12), (17, 14), (15, 16)], fill=pelo)
        d.line((19, 8, 24, 7), fill=pelo_l)
        d.line((27, 8, 31, 10), fill=pelo_l)
        puntos(d, [(15, 15), (16, 13)], (176, 168, 170, 255))
    elif nombre == "marcus":
        d.polygon([(13, 18), (13, 11), (16, 7), (21, 5), (27, 5), (31, 7), (34, 11), (34, 18), (32, 14), (30, 12),
                   (27, 13), (24, 11), (21, 13), (18, 11), (16, 13), (15, 15)], fill=pelo)
        d.line((20, 7, 26, 7), fill=pelo_l)
        d.line((17, 9, 19, 8), fill=pelo_l)
    elif nombre == "sofia":
        d.polygon([(13, 17), (14, 11), (17, 7), (23, 5), (29, 6), (33, 10), (34, 17), (32, 13), (28, 10), (23, 10),
                   (19, 13), (16, 17)], fill=pelo)
        d.line((18, 8, 24, 7), fill=pelo_l)
        d.line((26, 8, 30, 10), fill=pelo_l)
    else:  # leo
        d.polygon([(14, 15), (15, 10), (18, 8), (24, 7), (29, 8), (32, 10), (33, 15), (31, 12), (27, 10), (20, 10),
                   (16, 12)], fill=pelo)
        d.line((19, 9, 23, 8), fill=pelo_l)

    # 6) Cara segun la expresion
    ceja = pelo if nombre != "sofia" else (96, 44, 32, 255)
    cerrado_izq = expresion == "critico"
    cerrado_der = expresion in ("critico", "herido")

    # Cejas
    if expresion == "normal":
        d.line((17, 17, 21, 17), fill=ceja)
        d.line((26, 17, 30, 17), fill=ceja)
    elif expresion == "estresado":
        puntos(d, [(17, 18), (18, 18), (19, 17), (20, 17), (21, 16)], ceja)
        puntos(d, [(30, 18), (29, 18), (28, 17), (27, 17), (26, 16)], ceja)
    elif expresion == "herido":
        puntos(d, [(17, 16), (18, 16), (19, 17), (20, 17), (21, 18)], ceja)
        puntos(d, [(30, 17), (29, 17), (28, 18), (27, 18), (26, 18)], ceja)
    else:
        puntos(d, [(17, 18), (18, 18), (19, 18), (20, 17), (21, 17)], ceja)
        puntos(d, [(30, 18), (29, 18), (28, 18), (27, 17), (26, 17)], ceja)

    # Ojos
    def ojo(x0, cerrado):
        if cerrado:
            d.line((x0, 21, x0 + 3, 21), fill=oscuro)
            d.point((x0, 20), fill=oscuro) if x0 < 24 else d.point((x0 + 3, 20), fill=oscuro)
        else:
            d.line((x0, 19, x0 + 3, 19), fill=oscuro)
            d.rectangle((x0, 20, x0 + 3, 21), fill=blanco_ojo)
            if expresion == "estresado":
                d.rectangle((x0 + 1, 20, x0 + 2, 20), fill=(34, 28, 44, 255))   # pupila pequena: ojos muy abiertos
                d.line((x0, 22, x0 + 3, 22), fill=piel_s)
            else:
                d.rectangle((x0 + 1, 20, x0 + 2, 21), fill=(34, 28, 44, 255))

    ojo(18, cerrado_izq)
    ojo(26, cerrado_der)
    if nombre == "sofia" and expresion not in ("critico",):
        d.point((17, 19), fill=oscuro)
        if not cerrado_der:
            d.point((30, 19), fill=oscuro)

    # Nariz
    puntos(d, [(24, 22), (24, 23), (24, 24), (23, 25), (24, 25)], piel_s)

    # Boca y mejillas
    if expresion == "normal":
        if nombre == "leo":
            d.line((20, 27, 27, 27), fill=(246, 246, 240, 255))
            d.line((21, 28, 26, 28), fill=labios)
            puntos(d, [(19, 26), (28, 26)], labios)
        elif nombre == "marcus":
            d.line((21, 28, 26, 28), fill=labios)
            d.point((27, 27), fill=labios)
        else:
            d.line((21, 28, 26, 28), fill=labios)
            puntos(d, [(20, 27), (27, 27)], labios)
        rubor = mezclar(p["piel"], (230, 110, 110), 0.35) + (255,)
        puntos(d, [(17, 25), (18, 25), (29, 25), (30, 25)], rubor)
    elif expresion == "estresado":
        d.rectangle((21, 27, 26, 29), fill=(70, 30, 36, 255))
        d.line((21, 27, 26, 27), fill=(246, 246, 240, 255))
        d.line((22, 29, 25, 29), fill=(246, 246, 240, 255))
    elif expresion == "herido":
        d.line((21, 27, 26, 27), fill=labios)
        puntos(d, [(20, 28), (27, 28)], labios)

    # 7) Accesorios fijos
    if nombre == "marcus":
        marco = (40, 44, 62, 255)
        for (x0, x1) in ((16, 22), (25, 31)):
            d.rectangle((x0, 18, x1, 23), outline=marco)
        d.line((23, 20, 24, 20), fill=marco)
        d.line((13, 20, 15, 20), fill=marco)
        d.line((32, 20, 34, 20), fill=marco)
        puntos(d, [(17, 19), (26, 19)], (210, 236, 255, 255))
    if nombre == "leo":
        gris = (104, 110, 132, 255)
        d.line([(12, 18), (12, 12), (15, 7), (21, 4), (26, 4), (32, 7), (35, 12), (35, 18)], fill=gris)
        d.rectangle((10, 17, 13, 24), fill=(64, 68, 90, 255))
        d.point((11, 20), fill=acento)
        d.line((12, 25, 17, 30), fill=gris)
        d.rectangle((17, 29, 19, 31), fill=(40, 42, 58, 255))

    # 8) Extras de la expresion
    if expresion == "estresado":
        gota = (150, 216, 255, 255)
        puntos(d, [(36, 13), (36, 14), (37, 14), (36, 15), (37, 15)], gota)
        puntos(d, [(10, 12), (10, 13), (9, 13), (10, 14), (9, 14)], gota)
        puntos(d, [(29, 14), (29, 15)], gota)
    if expresion in ("herido", "critico"):
        venda = (244, 244, 240, 255)
        venda_s = (204, 204, 204, 255)
        d.rectangle((14, 12, 33, 15), fill=venda)
        d.line((14, 15, 33, 15), fill=venda_s)
        d.line((13, 13, 13, 14), fill=venda_s)
        d.line((34, 13, 34, 14), fill=venda_s)
        d.rectangle((27, 12, 29, 14), fill=(214, 60, 60, 255))
        d.point((28, 15), fill=(170, 40, 44, 255))
        puntos(d, [(17, 24), (18, 25), (17, 26)], (190, 50, 56, 255))
    if expresion == "herido":
        d.rectangle((27, 24, 30, 25), fill=(238, 214, 170, 255))
        d.point((28, 24), fill=(206, 176, 130, 255))
    if expresion == "critico":
        mascara = (196, 232, 238, 255)
        borde = (116, 168, 182, 255)
        d.polygon([(19, 23), (28, 23), (30, 28), (26, 31), (21, 31), (17, 28)], fill=mascara, outline=borde)
        d.line((21, 26, 26, 26), fill=borde)
        d.line((13, 22, 18, 25), fill=borde)
        d.line((34, 22, 29, 25), fill=borde)
        d.line((23, 31, 23, 36), fill=borde)
        d.line((24, 31, 24, 36), fill=mascara)

    img = contorno(img)

    if estado == "perdido":
        px = img.load()
        for y in range(48):
            for x in range(48):
                r, g, b, a = px[x, y]
                if a > 0:
                    gris = int((r * 0.3 + g * 0.59 + b * 0.11) * 0.55)
                    px[x, y] = (gris, gris, int(gris * 1.15) + 6, a)
    return img


# ----------------------------------------------------------------------------
# Nave Orion, capsula y paracaidas
# ----------------------------------------------------------------------------
def nave_orion():
    """Orion completa vista de lado (mira hacia la derecha). 96x64."""
    img = lienzo(96, 64)
    d = ImageDraw.Draw(img)
    azul = (52, 96, 196, 255)
    azul_l = (120, 166, 240, 255)
    marco = (150, 158, 178, 255)
    # Paneles solares (arriba y abajo)
    for (y0, y1) in ((2, 19), (44, 61)):
        d.rectangle((40, y0, 50, y1), fill=azul, outline=marco)
        paso = (y1 - y0) / 3.0
        for i in (1, 2):
            yy = int(y0 + paso * i)
            d.line((41, yy, 49, yy), fill=marco)
        d.line((45, y0 + 1, 45, y1 - 1), fill=azul_l)
    d.rectangle((44, 19, 46, 22), fill=marco)
    d.rectangle((44, 41, 46, 44), fill=marco)
    # Tobera del motor
    d.polygon([(18, 22), (26, 26), (26, 37), (18, 41)], fill=(86, 92, 112, 255))
    d.polygon([(26, 25), (34, 23), (34, 40), (26, 38)], fill=(120, 128, 150, 255))
    d.line((19, 24, 19, 39), fill=(140, 148, 168, 255))
    # Modulo de servicio
    d.rectangle((34, 20, 60, 43), fill=(222, 226, 236, 255))
    d.rectangle((36, 20, 40, 43), fill=(232, 190, 80, 255))
    d.line((48, 21, 48, 42), fill=(170, 178, 196, 255))
    d.line((54, 21, 54, 42), fill=(170, 178, 196, 255))
    d.rectangle((50, 26, 52, 30), fill=(150, 158, 178, 255))
    # Adaptador y escudo termico
    d.rectangle((60, 18, 63, 45), fill=(54, 58, 78, 255))
    # Capsula de la tripulacion
    d.polygon([(64, 18), (84, 27), (87, 29), (87, 34), (84, 36), (64, 45)], fill=(236, 240, 246, 255))
    d.rectangle((70, 25, 73, 27), fill=(52, 96, 196, 255))
    d.rectangle((70, 36, 73, 38), fill=(52, 96, 196, 255))
    d.rectangle((77, 30, 79, 33), fill=(52, 96, 196, 255))
    d.line((66, 20, 66, 43), fill=(190, 198, 214, 255))
    tono(img, lambda x, y: 20 <= y <= 46 and y > 35 and x >= 18, 0.8)
    return contorno(img)


def capsula(con_flotadores=False):
    """Modulo de tripulacion solo (para el amerizaje). 48x40."""
    img = lienzo(48, 40)
    d = ImageDraw.Draw(img)
    if con_flotadores:
        naranja = (244, 130, 40, 255)
        for (cx, cy) in ((16, 7), (24, 5), (32, 7)):
            d.ellipse((cx - 4, cy - 4, cx + 4, cy + 4), fill=naranja)
            d.point((cx - 2, cy - 2), fill=(255, 190, 120, 255))
    d.polygon([(19, 9), (28, 9), (43, 30), (4, 30)], fill=(232, 236, 244, 255))
    d.polygon([(28, 9), (43, 30), (33, 30), (25, 9)], fill=(190, 198, 214, 255))
    d.rectangle((19, 8, 28, 10), fill=(150, 158, 178, 255))
    d.rectangle((13, 20, 16, 23), fill=(52, 96, 196, 255))
    d.rectangle((22, 20, 25, 23), fill=(52, 96, 196, 255))
    d.rectangle((31, 20, 34, 23), fill=(40, 74, 150, 255))
    d.chord((4, 23, 43, 37), 0, 180, fill=(70, 62, 66, 255))
    d.line((6, 30, 41, 30), fill=(110, 96, 96, 255))
    return contorno(img)


def paracaidas():
    """Tres paracaidas principales de la Orion (naranja y blanco). 96x64."""
    img = lienzo(96, 64)
    d = ImageDraw.Draw(img)
    naranja = (240, 120, 44, 255)
    blanco = (244, 244, 240, 255)
    cuerda = (200, 204, 214, 255)
    centros = [(20, 18), (76, 18), (48, 12)]
    for (cx, cy) in centros:
        d.line((cx - 14, cy + 4, 48, 62), fill=cuerda)
        d.line((cx, cy + 6, 48, 62), fill=cuerda)
        d.line((cx + 14, cy + 4, 48, 62), fill=cuerda)
    for (cx, cy) in centros:
        d.chord((cx - 16, cy - 12, cx + 16, cy + 18), 180, 360, fill=naranja)
        for i, x0 in enumerate(range(cx - 16, cx + 16, 8)):
            if i % 2 == 1:
                d.rectangle((x0, cy - 12, x0 + 7, cy + 3), fill=blanco)
        # recorta lo que quedo fuera de la cupula
        px = img.load()
        for y in range(max(0, cy - 13), cy + 4):
            for x in range(max(0, cx - 17), min(96, cx + 18)):
                dx = (x - cx) / 16.5
                dy = (y - (cy + 3)) / 15.5
                if dx * dx + dy * dy > 1.0 and px[x, y][:3] in (blanco[:3], naranja[:3]):
                    px[x, y] = (0, 0, 0, 0)
        d.line((cx - 16, cy + 3, cx + 16, cy + 3), fill=(190, 90, 36, 255))
    return contorno(img)


# ----------------------------------------------------------------------------
# Fondos de los finales (320x180, se muestran ampliados x5)
# ----------------------------------------------------------------------------
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def degradado(img, y0, y1, colores):
    """Degradado vertical por bandas con tramado (dither) para que se vea pixel-art."""
    px = img.load()
    w = img.size[0]
    n = len(colores) - 1
    for y in range(y0, y1):
        t = (y - y0) / max(1, (y1 - y0 - 1)) * n
        i = min(int(t), n - 1)
        f = t - i
        for x in range(w):
            umbral = (BAYER[y % 4][x % 4] + 0.5) / 16.0
            c = colores[i + 1] if f > umbral else colores[i]
            px[x, y] = c + (255,)


def nube(d, cx, cy, ancho, color, sombra):
    d.ellipse((cx - ancho // 2, cy - 3, cx + ancho // 2, cy + 4), fill=sombra)
    d.ellipse((cx - ancho // 3, cy - 6, cx + ancho // 6, cy + 2), fill=color)
    d.ellipse((cx - ancho // 8, cy - 8, cx + ancho // 3, cy + 1), fill=color)
    d.ellipse((cx - ancho // 2 + 2, cy - 3, cx + ancho // 2 - 2, cy + 2), fill=color)


def fondo_final_bueno():
    rnd = random.Random(351)
    img = Image.new("RGBA", (320, 180), (0, 0, 0, 255))
    d = ImageDraw.Draw(img)
    degradado(img, 0, 112, [(30, 44, 110), (70, 70, 150), (170, 96, 140), (240, 130, 100), (255, 190, 120), (255, 226, 160)])
    # Sol
    d.ellipse((196, 84, 252, 140), fill=(255, 214, 140, 255))
    d.ellipse((202, 90, 246, 134), fill=(255, 236, 180, 255))
    d.ellipse((210, 98, 238, 126), fill=(255, 250, 224, 255))
    # Nubes
    nube(d, 60, 34, 60, (255, 214, 200, 255), (214, 150, 170, 255))
    nube(d, 150, 22, 44, (250, 200, 196, 255), (200, 140, 170, 255))
    nube(d, 276, 46, 52, (255, 222, 200, 255), (224, 160, 160, 255))
    nube(d, 110, 70, 36, (255, 226, 204, 255), (236, 170, 150, 255))
    # Mar
    degradado(img, 112, 180, [(60, 120, 190), (40, 96, 170), (26, 70, 140), (16, 44, 100)])
    for y in range(113, 180):
        ancho = 10 + (y - 112) // 2
        for _ in range(3):
            x = 224 + rnd.randint(-ancho, ancho)
            largo = rnd.randint(2, 6)
            d.line((x, y, x + largo, y), fill=(255, 220, 150, 255))
    for _ in range(150):
        y = rnd.randint(114, 179)
        x = rnd.randint(0, 319)
        largo = rnd.randint(2, 3 + (y - 112) // 8)
        d.line((x, y, x + largo, y), fill=(120, 180, 230, 255))
    d.line((0, 112, 319, 112), fill=(255, 236, 190, 255))
    # Barco de rescate en el horizonte
    gris = (40, 48, 80, 255)
    d.polygon([(22, 112), (26, 106), (62, 106), (68, 112)], fill=gris)
    d.rectangle((36, 99, 50, 106), fill=gris)
    d.rectangle((41, 93, 44, 99), fill=gris)
    d.line((42, 86, 42, 93), fill=gris)
    d.point((42, 85), fill=(255, 90, 90, 255))
    puntos(d, [(38, 102), (42, 102), (46, 102)], (255, 230, 150, 255))
    return img


def fondo_final_intermedio():
    rnd = random.Random(352)
    img = Image.new("RGBA", (320, 180), (0, 0, 0, 255))
    d = ImageDraw.Draw(img)
    degradado(img, 0, 110, [(36, 38, 58), (56, 58, 84), (84, 84, 110), (120, 114, 134), (150, 140, 150)])
    oscuro = (44, 46, 68, 255)
    medio = (66, 68, 94, 255)
    nube(d, 50, 26, 90, medio, oscuro)
    nube(d, 160, 16, 110, medio, oscuro)
    nube(d, 270, 30, 96, medio, oscuro)
    nube(d, 110, 54, 70, (90, 90, 116, 255), (64, 66, 90, 255))
    nube(d, 230, 62, 80, (90, 90, 116, 255), (64, 66, 90, 255))
    degradado(img, 110, 180, [(70, 84, 110), (50, 62, 90), (34, 44, 70), (20, 26, 46)])
    for _ in range(110):
        y = rnd.randint(112, 179)
        x = rnd.randint(0, 319)
        largo = rnd.randint(2, 3 + (y - 110) // 8)
        d.line((x, y, x + largo, y), fill=(110, 124, 150, 255))
    d.line((0, 110, 319, 110), fill=(160, 152, 160, 255))
    # Lluvia fina
    for _ in range(170):
        x = rnd.randint(0, 319)
        y = rnd.randint(0, 175)
        d.line((x, y, x - 1, y + 3), fill=(150, 160, 184, 255))
    # Helicoptero lejano
    gris = (24, 26, 40, 255)
    d.rectangle((250, 70, 262, 75), fill=gris)
    d.line((262, 72, 272, 71), fill=gris)
    d.line((244, 67, 268, 67), fill=gris)
    d.line((256, 67, 256, 70), fill=gris)
    d.point((249, 73), fill=(255, 90, 90, 255))
    return img


# ----------------------------------------------------------------------------
# Escena del despegue: cohete, torre y fondo de Cabo Canaveral
# ----------------------------------------------------------------------------
def cohete():
    """Cohete lunar con la Orion en la punta. 48x160."""
    img = lienzo(48, 160)
    d = ImageDraw.Draw(img)
    naranja = (226, 124, 52, 255)
    naranja_s = (178, 90, 36, 255)
    blanco = (236, 240, 246, 255)
    gris = (176, 184, 200, 255)
    oscuro = (60, 64, 84, 255)
    # Etapa central
    d.rectangle((18, 44, 29, 138), fill=naranja)
    d.rectangle((26, 44, 29, 138), fill=naranja_s)
    d.rectangle((18, 44, 29, 46), fill=oscuro)
    d.rectangle((18, 96, 29, 97), fill=naranja_s)
    # Propulsores laterales
    for x0 in (9, 31):
        d.rectangle((x0, 70, x0 + 7, 140), fill=blanco)
        d.rectangle((x0 + 5, 70, x0 + 7, 140), fill=gris)
        d.polygon([(x0, 70), (x0 + 7, 70), (x0 + 4, 58), (x0 + 3, 58)], fill=blanco)
        d.rectangle((x0, 92, x0 + 7, 93), fill=oscuro)
        d.rectangle((x0, 118, x0 + 7, 119), fill=oscuro)
        d.polygon([(x0 + 1, 140), (x0 + 6, 140), (x0 + 8, 148), (x0 - 1, 148)], fill=oscuro)
    # Etapa superior
    d.polygon([(18, 44), (29, 44), (27, 34), (20, 34)], fill=blanco)
    d.rectangle((20, 24, 27, 34), fill=blanco)
    d.rectangle((25, 24, 27, 34), fill=gris)
    d.rectangle((20, 29, 27, 29), fill=(48, 96, 190, 255))
    # Modulo de servicio y capsula Orion
    d.rectangle((20, 18, 27, 24), fill=gris)
    d.polygon([(20, 18), (27, 18), (25, 11), (22, 11)], fill=blanco)
    # Torre de escape
    d.rectangle((23, 2, 24, 11), fill=gris)
    d.polygon([(22, 4), (25, 4), (24, 0), (23, 0)], fill=blanco)
    # Motores centrales
    d.rectangle((19, 138, 28, 141), fill=oscuro)
    for x0 in (19, 25):
        d.polygon([(x0, 141), (x0 + 3, 141), (x0 + 4, 147), (x0 - 1, 147)], fill=(96, 102, 122, 255))
    return contorno(img)


def torre_lanzamiento():
    """Torre de servicio de la plataforma. 56x170."""
    img = lienzo(56, 170)
    d = ImageDraw.Draw(img)
    gris = (124, 132, 154, 255)
    oscuro = (84, 90, 112, 255)
    d.rectangle((6, 10, 9, 169), fill=gris)
    d.rectangle((26, 10, 29, 169), fill=gris)
    for y in range(10, 166, 16):
        d.line((9, y, 26, y + 15), fill=oscuro)
        d.line((26, y, 9, y + 15), fill=oscuro)
        d.line((6, y, 29, y), fill=gris)
    for y in (40, 84, 124):
        d.rectangle((29, y, 50, y + 3), fill=gris)
        d.rectangle((48, y, 51, y + 8), fill=oscuro)
    d.rectangle((17, 0, 18, 10), fill=gris)
    d.point((17, 0), fill=(255, 90, 90, 255))
    d.point((18, 0), fill=(255, 90, 90, 255))
    return contorno(img)


def fondo_despegue():
    rnd = random.Random(353)
    img = Image.new("RGBA", (320, 180), (0, 0, 0, 255))
    d = ImageDraw.Draw(img)
    degradado(img, 0, 140, [(8, 12, 36), (20, 26, 72), (60, 50, 116), (170, 92, 112), (246, 156, 100), (255, 214, 150)])
    for _ in range(60):
        d.point((rnd.randint(0, 319), rnd.randint(0, 62)), fill=(255, 255, 255, 255))
    # Mar al fondo
    degradado(img, 140, 148, [(70, 110, 170), (40, 76, 136)])
    for _ in range(40):
        x = rnd.randint(0, 319)
        d.line((x, rnd.randint(141, 147), x + rnd.randint(2, 5), rnd.randint(141, 147)), fill=(255, 210, 150, 255))
    # Edificio de ensamblaje y tanque a lo lejos
    silueta = (26, 30, 56, 255)
    d.rectangle((18, 112, 50, 140), fill=silueta)
    d.rectangle((50, 126, 70, 140), fill=silueta)
    puntos(d, [(24, 118), (30, 124), (38, 118), (44, 130), (56, 132), (62, 132)], (255, 226, 140, 255))
    d.ellipse((268, 118, 284, 132), fill=silueta)
    d.rectangle((274, 130, 278, 140), fill=silueta)
    # Terreno
    degradado(img, 148, 180, [(40, 58, 54), (28, 42, 42), (16, 24, 28)])
    # Plataforma de lanzamiento
    d.polygon([(112, 156), (208, 156), (220, 168), (100, 168)], fill=(96, 100, 112, 255))
    d.rectangle((112, 152, 208, 156), fill=(140, 144, 156, 255))
    d.rectangle((150, 156, 170, 168), fill=(30, 30, 38, 255))
    for x in (120, 136, 184, 200):
        d.point((x, 153), fill=(255, 226, 140, 255))
    return img


# ----------------------------------------------------------------------------
# Hojas de revision (para ver todo junto mientras se disena)
# ----------------------------------------------------------------------------
def hoja(imagenes, columnas, escala, fondo=(46, 50, 76, 255), margen=6):
    if not imagenes:
        return None
    w = max(i.width for i in imagenes) * escala
    h = max(i.height for i in imagenes) * escala
    filas = (len(imagenes) + columnas - 1) // columnas
    sheet = Image.new("RGBA", (columnas * (w + margen) + margen, filas * (h + margen) + margen), fondo)
    for n, im in enumerate(imagenes):
        g = im.resize((im.width * escala, im.height * escala), Image.NEAREST)
        x = margen + (n % columnas) * (w + margen)
        y = margen + (n // columnas) * (h + margen)
        sheet.paste(g, (x, y), g)
    return sheet


def main(revision_dir=None):
    iconos = {
        "electricidad": icono_electricidad(),
        "salud": icono_salud(),
        "comida": icono_comida(),
        "oxigeno": icono_oxigeno(),
        "combustible": icono_combustible(),
        "temperatura": icono_temperatura(),
        "integridad": icono_integridad(),
        "datos": icono_datos(),
        "ciencia": icono_ciencia(),
        "estres": icono_estres(),
        "hambre": icono_hambre(),
        "confianza": icono_confianza(),
        "reloj": icono_reloj(),
        "alarma": icono_alarma(),
        "memo": icono_memo(),
        "resultado_bueno": icono_resultado("bueno"),
        "resultado_intermedio": icono_resultado("intermedio"),
        "resultado_malo": icono_resultado("malo"),
        "enlace": icono_enlace(),
        "racion_completa": icono_racion("completa"),
        "racion_reducida": icono_racion("reducida"),
        "racion_minima": icono_racion("minima"),
        "higiene_normal": icono_higiene(False),
        "higiene_suspendida": icono_higiene(True),
        "instrumentos_apagados": icono_instrumentos("apagados"),
        "instrumentos_basicos": icono_instrumentos("basicos"),
        "instrumentos_todos": icono_instrumentos("todos"),
        "sonido_on": icono_sonido(True),
        "sonido_off": icono_sonido(False),
        "pulso": icono_pulso(True),
        "sin_senal": icono_pulso(False),
        "tierra": icono_tierra_mini(),
        "luna": icono_luna_mini(),
        "orion_mini": icono_orion_mini(),
        "herramienta": icono_herramienta(),
        "flecha_sube": icono_flecha(True),
        "flecha_baja": icono_flecha(False),
        "ayuda": icono_ayuda(),
    }
    for nombre, img in iconos.items():
        guardar(img, "iconos", nombre + ".png")

    retratos = []
    for nombre in PERSONAJES:
        for estado in ESTADOS:
            img = retrato(nombre, estado)
            guardar(img, "retratos", "%s_%s.png" % (nombre, estado))
            retratos.append(img)

    nave = {
        "orion": nave_orion(),
        "capsula": capsula(False),
        "capsula_flotando": capsula(True),
        "paracaidas": paracaidas(),
    }
    for nombre, img in nave.items():
        guardar(img, "nave", nombre + ".png")

    nave["cohete"] = cohete()
    nave["torre"] = torre_lanzamiento()
    for nombre in ("cohete", "torre"):
        guardar(nave[nombre], "nave", nombre + ".png")

    fondos = {"final_bueno": fondo_final_bueno(), "final_intermedio": fondo_final_intermedio(), "despegue": fondo_despegue()}
    for nombre, img in fondos.items():
        guardar(img, "finales", nombre + ".png")

    if revision_dir:
        os.makedirs(revision_dir, exist_ok=True)
        hoja(list(iconos.values()), 12, 4).save(os.path.join(revision_dir, "hoja_iconos.png"))
        hoja(retratos, 5, 5).save(os.path.join(revision_dir, "hoja_retratos.png"))
        hoja(list(nave.values()), 4, 4).save(os.path.join(revision_dir, "hoja_nave.png"))
        for nombre, img in fondos.items():
            img.resize((960, 540), Image.NEAREST).save(os.path.join(revision_dir, nombre + "_x3.png"))
    print("Arte generado en", ASSETS)


if __name__ == "__main__":
    import sys
    main(sys.argv[1] if len(sys.argv) > 1 else None)
