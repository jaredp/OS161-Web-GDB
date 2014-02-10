
module.exports = (grunt) ->
	grunt.initConfig({
		pkg: grunt.file.readJSON('package.json')

		coffee: {
			compile: {
				expand: true
				flatten: true
				cwd: 'app'
				src: ['source/*.coffee']
				dest: 'app/scripts/'
				ext: '.js'
				options: {
					sourceMap: true
				}
			}
		}

		watch: {
			options: {
				livereload: true
				nospawn: true
			}
			scripts: {
				files: 'app/**/*.{coffee,html,css}'
				tasks: ['coffee']
			}
			express: {
				files:  [ 'server/**/*.coffee' ]
				tasks:  [ 'express:dev' ]
				options: {
					spawn: false
				}
			}
		}

		express: {
			dev: {
				options: {
					cmd: 'coffee'
					script: 'server/server.coffee'
					port: 3000
					delay: 1
				}
			}
		}

	})

	grunt.loadNpmTasks('grunt-contrib-coffee')
	grunt.loadNpmTasks('grunt-contrib-watch')
	grunt.loadNpmTasks('grunt-express-server')

	grunt.registerTask 'default', ['coffee', 'express:dev', 'watch']


