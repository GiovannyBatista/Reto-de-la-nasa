#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Genera los sonidos de MYG-351: Last Signal por sintesis (no usa grabaciones).

Uso (desde la carpeta del proyecto):
    python tools/generar_audio.py

Necesita numpy:  pip install numpy

Lista de audio del documento de diseno (GDD):
  - Zumbido ambiental constante de soporte vital        -> zumbido.wav (bucle)
  - Alarmas de emergencia                               -> alarma.wav
  - Efectos de clics de terminal                        -> clic.wav, tic.wav
  - Estatica de radio                                   -> estatica.wav
  - Musica tensa para los Actos I-II                    -> musica_tension.wav (bucle)
  - Musica contrarreloj para el Acto III                -> musica_contrarreloj.wav (bucle)
Ademas: exito.wav, aviso.wav, fallo.wav, final_bueno.wav, final_intermedio.wav, linea_plana.wav

Si consigues sonidos mejores (grabados o de una libreria libre), reemplaza el .wav
con el MISMO nombre y el juego los usara sin tocar codigo.
"""
import os
import wave

import numpy as np

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SALIDA = os.path.join(RAIZ, "assets", "audio")
FS = 22050


def tiempo(seg):
    return np.arange(int(FS * seg)) / FS


def guardar(nombre, x, pico=0.6):
    x = np.asarray(x, dtype=np.float64)
    m = np.max(np.abs(x))
    if m > 0:
        x = x / m * pico
    datos = (x * 32767.0).astype(np.int16)
    os.makedirs(SALIDA, exist_ok=True)
    with wave.open(os.path.join(SALIDA, nombre), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(FS)
        w.writeframes(datos.tobytes())


def ruido_ciclico(seg, f_min, f_max, semilla):
    """Ruido filtrado que se repite sin corte (se construye en frecuencia)."""
    n = int(FS * seg)
    rnd = np.random.default_rng(semilla)
    espectro = np.zeros(n // 2 + 1, dtype=np.complex128)
    freqs = np.fft.rfftfreq(n, 1.0 / FS)
    banda = (freqs >= f_min) & (freqs <= f_max)
    espectro[banda] = rnd.normal(size=banda.sum()) + 1j * rnd.normal(size=banda.sum())
    x = np.fft.irfft(espectro, n)
    return x / np.max(np.abs(x))


def envolvente(n, ataque, caida):
    """Sube en 'ataque' segundos y baja de forma exponencial con constante 'caida'."""
    t = np.arange(n) / FS
    e = np.exp(-t / caida)
    a = int(FS * ataque)
    if a > 0:
        e[:a] *= np.linspace(0.0, 1.0, a)
    return e


def nota(freq, seg, ataque=0.01, caida=0.25, armonicos=(1.0, 0.3, 0.1)):
    t = tiempo(seg)
    x = np.zeros_like(t)
    for i, amp in enumerate(armonicos):
        x += amp * np.sin(2 * np.pi * freq * (i + 1) * t)
    return x * envolvente(len(t), ataque, caida)


def poner(pista, x, inicio_seg, ciclico=False):
    """Suma 'x' dentro de 'pista' a partir de inicio_seg (si ciclico, la cola da la vuelta)."""
    i = int(inicio_seg * FS)
    n = len(pista)
    if ciclico:
        idx = (i + np.arange(len(x))) % n
        np.add.at(pista, idx, x)
    else:
        fin = min(n, i + len(x))
        pista[i:fin] += x[: fin - i]


# ----------------------------------------------------------------------------
# Efectos
# ----------------------------------------------------------------------------
def zumbido():
    seg = 4.0
    t = tiempo(seg)
    x = 0.50 * np.sin(2 * np.pi * 60 * t) + 0.24 * np.sin(2 * np.pi * 120 * t) + 0.10 * np.sin(2 * np.pi * 180 * t)
    x *= 1.0 + 0.10 * np.sin(2 * np.pi * 0.25 * t)
    x += 0.35 * ruido_ciclico(seg, 80, 700, 1)
    x += 0.10 * ruido_ciclico(seg, 1500, 4000, 2)
    guardar("zumbido.wav", x, 0.5)


def alarma():
    x = np.zeros(int(FS * 1.3))
    for i, f in enumerate((880, 660, 880, 660)):
        t = tiempo(0.26)
        tono = np.sin(2 * np.pi * f * t) + 0.35 * np.sin(2 * np.pi * 2 * f * t) + 0.2 * np.sin(2 * np.pi * 3 * f * t)
        env = np.minimum(1.0, np.minimum(t / 0.01, (0.26 - t) / 0.04))
        poner(x, tono * env, i * 0.31)
    guardar("alarma.wav", x, 0.5)


def clic():
    t = tiempo(0.07)
    f = 1500 * np.exp(-t * 18) + 500
    x = np.sin(2 * np.pi * np.cumsum(f) / FS) * np.exp(-t / 0.012)
    guardar("clic.wav", x, 0.45)


def tic():
    t = tiempo(0.05)
    x = np.sin(2 * np.pi * 1000 * t) * np.exp(-t / 0.008)
    guardar("tic.wav", x, 0.4)


def estatica():
    seg = 0.9
    t = tiempo(seg)
    rnd = np.random.default_rng(7)
    x = ruido_ciclico(seg, 900, 5000, 3)
    crujido = 0.6 + 0.4 * np.repeat(rnd.random(int(seg * 60) + 1), FS // 60 + 1)[: len(t)]
    env = np.minimum(1.0, np.minimum(t / 0.04, (seg - t) / 0.25))
    x = x * crujido * env
    bip = np.sin(2 * np.pi * 1320 * tiempo(0.12)) * envolvente(int(FS * 0.12), 0.005, 0.06)
    poner(x, 0.8 * bip, 0.72)
    guardar("estatica.wav", x, 0.4)


def exito():
    x = np.zeros(int(FS * 1.1))
    for i, f in enumerate((523.25, 659.25, 783.99, 1046.5)):
        poner(x, nota(f, 0.6, caida=0.18), i * 0.11)
    guardar("exito.wav", x, 0.5)


def aviso():
    x = np.zeros(int(FS * 0.6))
    for i, f in enumerate((587.33, 587.33)):
        poner(x, nota(f, 0.25, caida=0.08), i * 0.16)
    guardar("aviso.wav", x, 0.45)


def fallo():
    x = np.zeros(int(FS * 1.2))
    for i, f in enumerate((440.0, 349.23, 277.18)):
        poner(x, nota(f, 0.7, caida=0.22, armonicos=(1.0, 0.5, 0.3, 0.2)), i * 0.16)
    guardar("fallo.wav", x, 0.5)


def linea_plana():
    """Monitor cardiaco: tres pulsos y luego la linea plana (para el final malo)."""
    x = np.zeros(int(FS * 6.0))
    for i in range(3):
        poner(x, nota(880, 0.14, ataque=0.005, caida=0.2, armonicos=(1.0,)), 0.2 + i * 0.9)
    t = tiempo(3.2)
    plano = np.sin(2 * np.pi * 880 * t) * np.minimum(1.0, (3.2 - t) / 1.2)
    poner(x, plano, 2.8)
    guardar("linea_plana.wav", x, 0.35)


def despegue():
    """Rugido grave de los motores: empieza de golpe, crece y se aleja."""
    seg = 8.0
    t = tiempo(seg)
    x = 1.0 * ruido_ciclico(seg, 25, 220, 21) + 0.5 * ruido_ciclico(seg, 220, 900, 22) + 0.2 * ruido_ciclico(seg, 900, 3500, 23)
    env = np.minimum(1.0, t / 0.9) * np.minimum(1.0, (seg - t) / 3.0)
    crujido = 0.8 + 0.2 * np.sin(2 * np.pi * 11.0 * t) * np.sin(2 * np.pi * 0.7 * t)
    guardar("despegue.wav", x * env * crujido, 0.6)


def acorde(freqs, seg, ataque, caida_final):
    t = tiempo(seg)
    x = np.zeros_like(t)
    for f in freqs:
        x += np.sin(2 * np.pi * f * t) + 0.4 * np.sin(2 * np.pi * f * 1.003 * t) + 0.15 * np.sin(2 * np.pi * 2 * f * t)
    env = np.minimum(1.0, np.minimum(t / ataque, (seg - t) / caida_final))
    return x * env


def final_bueno():
    x = np.zeros(int(FS * 6.0))
    poner(x, acorde((130.81, 196.0, 261.63, 329.63), 3.0, 0.6, 1.2), 0.0)
    poner(x, acorde((174.61, 220.0, 261.63, 349.23), 2.6, 0.4, 1.0), 1.6)
    poner(x, acorde((130.81, 261.63, 329.63, 392.0, 523.25), 3.0, 0.4, 1.8), 3.0)
    for i, f in enumerate((523.25, 659.25, 783.99, 1046.5, 1318.5)):
        poner(x, 0.6 * nota(f, 1.2, caida=0.4), 3.0 + i * 0.16)
    guardar("final_bueno.wav", x, 0.5)


def final_intermedio():
    x = np.zeros(int(FS * 6.0))
    poner(x, acorde((110.0, 164.81, 220.0, 261.63), 3.4, 0.8, 1.6), 0.0)
    poner(x, acorde((87.31, 174.61, 220.0, 261.63), 3.6, 0.8, 2.2), 2.4)
    for i, f in enumerate((659.25, 523.25, 440.0)):
        poner(x, 0.5 * nota(f, 1.6, caida=0.6), 1.0 + i * 1.1)
    guardar("final_intermedio.wav", x, 0.45)


# ----------------------------------------------------------------------------
# Musica (bucles sin corte: todas las frecuencias dan vueltas completas)
# ----------------------------------------------------------------------------
def colchon(seg, notas_hz):
    """Acorde sostenido con movimiento lento; cada frecuencia se ajusta para cerrar el bucle."""
    t = tiempo(seg)
    x = np.zeros_like(t)
    for i, f in enumerate(notas_hz):
        ciclos = round(f * seg)
        f1 = ciclos / seg
        f2 = (ciclos + 2 + i) / seg                     # desafinado leve: efecto "coro"
        lfo = 0.6 + 0.4 * np.sin(2 * np.pi * (i + 1) * t / seg + i * 1.3)
        x += lfo * (np.sin(2 * np.pi * f1 * t) + 0.5 * np.sin(2 * np.pi * f2 * t) + 0.12 * np.sin(2 * np.pi * 2 * f1 * t))
    return x


def musica_tension():
    seg = 16.0
    x = 0.5 * colchon(seg, (55.0, 110.0, 164.81, 220.0, 261.63))
    x += 0.06 * ruido_ciclico(seg, 300, 1800, 11)
    # Notas sueltas, lejanas (la minor: la, do, mi, sol)
    melodia = [(0.0, 880.0), (2.0, 659.25), (3.5, 1046.5), (6.0, 783.99), (8.0, 880.0), (9.5, 587.33),
               (11.0, 659.25), (13.0, 523.25), (14.5, 783.99)]
    for inicio, f in melodia:
        poner(x, 0.33 * nota(f, 2.6, ataque=0.02, caida=0.8, armonicos=(1.0, 0.2)), inicio, ciclico=True)
    guardar("musica_tension.wav", x, 0.45)


def musica_contrarreloj():
    seg = 8.0
    x = 0.42 * colchon(seg, (55.0, 110.0, 164.81, 233.08))
    # Pulso grave en corcheas (120 pulsos por minuto)
    for i in range(32):
        fuerza = 1.0 if i % 4 == 0 else 0.6
        poner(x, 0.75 * fuerza * nota(55.0 if i % 8 < 6 else 61.74, 0.22, ataque=0.004, caida=0.07, armonicos=(1.0, 0.6, 0.3)),
              i * 0.25, ciclico=True)
    # Tic de reloj
    rnd = np.random.default_rng(5)
    for i in range(16):
        tic_ = rnd.normal(size=int(FS * 0.03)) * np.exp(-np.arange(int(FS * 0.03)) / (FS * 0.006))
        poner(x, 0.22 * tic_, i * 0.5 + 0.25, ciclico=True)
    # Cuerda aguda tensa que alterna medio tono
    for i, f in enumerate((659.25, 698.46, 659.25, 622.25)):
        t = tiempo(2.0)
        cuerda = np.sin(2 * np.pi * round(f * 2.0) / 2.0 * t) * np.minimum(1.0, np.minimum(t / 0.5, (2.0 - t) / 0.5))
        poner(x, 0.16 * cuerda, i * 2.0, ciclico=True)
    guardar("musica_contrarreloj.wav", x, 0.45)


def main():
    zumbido()
    alarma()
    clic()
    tic()
    estatica()
    exito()
    aviso()
    fallo()
    linea_plana()
    despegue()
    final_bueno()
    final_intermedio()
    musica_tension()
    musica_contrarreloj()
    print("Audio generado en", SALIDA)
    for f in sorted(os.listdir(SALIDA)):
        if f.endswith(".wav"):
            print("  %-26s %7.1f KB" % (f, os.path.getsize(os.path.join(SALIDA, f)) / 1024.0))


if __name__ == "__main__":
    main()
