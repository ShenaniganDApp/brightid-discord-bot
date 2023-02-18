const { fontFamily } = require('tailwindcss/defaultTheme')
const plugin = require('tailwindcss/plugin')

module.exports = {
  content: ['./app/**/*.{js,jsx,res}'],
  theme: {
    fontFamily: {
      poppins: ['Poppins', ...fontFamily.sans],
      pressStart: ['"Press Start 2P"', ...fontFamily.sans],
    },
    extend: {
      backgroundImage: {
        discordLogo: "url('/assets/discord_logo.png')",
      },
      colors: {
        primary: {
          400: '#00E0F3',
          500: '#00c4fd',
        },
        dark: '#1E1E1E',
        extraDark: '#121212',
        brightid: '#ed7a5c',
        disabled: '#fff0ed',
        discord: '#5865f2',
        brightOrange: '#EC6041',
        brightBlue: '#2F69FE',
        brightGreen: '#44EC41',
      },
      animation: {
        textscroll: 'bg 25s linear infinite',
      },
      aspectRatio: { '87/74': 87 / 74 },
    },
  },
  variants: {
    width: ['responsive'],
  },

  plugins: [],
}
