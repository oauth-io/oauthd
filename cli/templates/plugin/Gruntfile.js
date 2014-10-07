
module.exports = function(grunt) {
	grunt.initConfig({
		coffee: {
			default: {
				expand: true,
				cwd: __dirname,
				src: ['*.coffee'],
				dest: 'bin',
				ext: '.js',
				options: {
					bare: true
				}
			}
		}
	});

	grunt.loadNpmTasks('grunt-contrib-coffee');

	grunt.registerTask('default', ['coffee']);
};